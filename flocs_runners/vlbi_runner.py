from .utils import (
    cwl_file,
    cwl_dir,
    add_apptainer_skeleton,
    add_slurm_skeleton,
    check_dd_freq,
    get_prefactor_freqs,
    setup_toil_slurm,
    verify_slurm_environment_toil,
)
import glob
import json
import os
import sys
import structlog
import subprocess
import tempfile
import typer
from enum import Enum
from typer import Argument, Option
from typing import List, Optional, Tuple
from typing_extensions import Annotated


class VLBIJSONConfig:
    """Class for generating JSON configuration files to be passed to the VLBI-cwl pipeline."""

    class OBS_TYPE(Enum):
        DELAY = "delay-calibration"
        SPLIT_DIRECTIONS = "split-directions"

    def __init__(
        self,
        mspath: str,
        ms_suffix: str = ".MS",
        prefac_h5parm={"path": ""},
        update_version_file: bool = False,
    ):
        if "VLBI_DATA_ROOT" not in os.environ:
            logger.critical(
                "VLBI_DATA_ROOT environment variable has not been set. This is needed for pipeline execution."
            )
            sys.exit(-1)

        self.configdict = {}

        filedir = os.path.join(mspath, f"*{ms_suffix}")
        logger.info(f"Searching {filedir}")
        files = sorted(glob.glob(filedir))
        logger.info(f"Found {len(files)} files")

        if not prefac_h5parm["path"].endswith("h5") and not prefac_h5parm[
            "path"
        ].endswith("h5parm"):
            mslist = []
            for ms in files:
                x = json.loads(f'{{"class": "Directory", "path":"{ms}"}}')
                mslist.append(x)
            self.configdict["msin"] = mslist
        else:
            prefac_freqs = get_prefactor_freqs(
                solname=prefac_h5parm["path"], solset="calibrator"
            )

            mslist = []
            for dd in files:
                if check_dd_freq(dd, prefac_freqs):
                    mslist.append(dd)

            final_mslist = []
            for ms in mslist:
                x = json.loads(f'{{"class": "Directory", "path":"{ms}"}}')
                final_mslist.append(x)
            self.configdict["msin"] = final_mslist
        self.create_linc_versions_file(update_version_file)

    def add_entry(self, key: str, value: object):
        if "ATeam" in key:
            self.configdict["A-Team_skymodel"] = value
        else:
            self.configdict[key] = value

    def create_linc_versions_file(self, overwrite=False):
        if "LINC_DATA_ROOT" not in os.environ:
            raise ValueError(
                "WARNING: LINC_DATA_ROOT environment variable has not been set. Cannot generate $LINC_DATA_ROOT/.versions file."
            )
        linc_version = subprocess.check_output(
            f"cd {os.environ["LINC_DATA_ROOT"]} && git describe --tags",
            shell=True,
            text=True,
        )
        pip_versions = subprocess.check_output(
            "pip freeze | sed 's/==/: /g'", shell=True
        )
        linc_version_file = os.path.join(os.environ["LINC_DATA_ROOT"], ".versions")

        if os.path.isfile(linc_version_file) and not overwrite:
            logger.info(f"Using existing {os.environ['LINC_DATA_ROOT']}/.versions")
        if not os.path.isfile(linc_version_file) or overwrite:
            with open(linc_version_file, "wb") as f:
                f.write(f"LINC: {linc_version}".encode("utf-8"))
                f.write(pip_versions)

    def save(self, fname: str):
        if not fname.endswith(".json"):
            fname += ".json"
        with open(fname, "w") as outfile:
            json.dump(self.configdict, outfile, indent=4)
        logger.info(f"Written configuration to {fname}")
        self.configfile = fname

    def setup_rundir(self, workdir):
        if "delay" in self.configfile:
            self.rundir = tempfile.mkdtemp(
                prefix="tmp.VLBI_delay_calibration.", dir=workdir
            )
        elif "split" in self.configfile:
            self.rundir = tempfile.mkdtemp(
                prefix="tmp.VLBI_split_directions.", dir=workdir
            )
        else:
            logger.warning("Unknown config file passed; exiting.")
            sys.exit(-1)

    def deduce_pipeline_mode(self):
        if self.configfile is None:
            raise RuntimeError("No config file has been created. Save it first.")
        elif "delay" in self.configfile:
            self.mode = self.OBS_TYPE.DELAY
        elif "split" in self.configfile:
            self.mode = self.OBS_TYPE.SPLIT_DIRECTIONS
        elif ("delay" not in self.configfile) and ("split" not in self.configfile):
            raise RuntimeError(
                "Cannot deduce VLBI workflow to run from config file name. Ensure either `delay` or `split` is present in the file name."
            )
        else:
            raise RuntimeError("Something unexpected went wrong with the config file.")

    def run_workflow(
        self,
        runner: str = "toil",
        scheduler: str = "slurm",
        workdir: str = os.getcwd(),
        container: str = "",
        slurm_params: dict = {},
    ):
        self.deduce_pipeline_mode()
        self.setup_rundir(workdir)
        self.setup_apptainer_variables(self.rundir)
        logger.info(
            f"Running workflow with {runner} under {scheduler} in {self.rundir}"
        )

        if runner == "cwltool":
            cmd = (
                "cwltool "
                + "--parallel "
                + "--preserve-entire-environment "
                + "--no-container "
                + f"--tmpdir-prefix={os.environ['APPTAINERENV_TMPDIR']} "
                + f"--outdir={os.environ['APPTAINERENV_RESULTSDIR']} "
                + f"--log-dir={os.environ['APPTAINERENV_LOGSDIR']} "
            )
            cmd += f"{os.environ['VLBI_DATA_ROOT']}/workflows/{self.mode.value}.cwl "
            cmd += f"{self.configfile}"

            if scheduler == "slurm":
                if container:
                    cmd = add_apptainer_skeleton(contents=cmd, container=container)
                wrapped_cmd = add_slurm_skeleton(
                    contents=cmd,
                    time="24:00:00",
                    cores=32,
                    job_name=f"VLBI_{self.mode.value}",
                    **slurm_params,
                )
                with open("temp_jobscript.sh", "w") as f:
                    f.write(wrapped_cmd)
                logger.info("Written temporary jobscript to temp_jobscript.sh")
                out = subprocess.check_output(["sbatch", "temp_jobscript.sh"]).decode(
                    "utf-8"
                )
            elif scheduler == "singleMachine":
                if container:
                    cmd = add_apptainer_skeleton(contents=cmd, container=container)
                logger.info(f"Running command:\n{cmd}")
                out = subprocess.check_output(cmd.split(" ")).decode("utf-8")
                print(out)
        elif runner == "toil":
            verify_slurm_environment_toil()
            dir_coordination, dir_slurmlogs = self.setup_toil_directories(self.rundir)
            setup_toil_slurm(slurm_params)
            cmd = ["toil-cwl-runner"]
            if scheduler == "slurm":
                cmd += ["--batchSystem", "slurm"]
            elif scheduler == "singleMachine":
                cmd += ["--batchSystem", "singleMachine"]
            else:
                raise ValueError(f"Unsupported scheduler `{scheduler}` provided.")
            cmd += ["--no-read-only"]
            cmd += ["--retryCount", "3"]
            cmd += ["--singularity"]
            cmd += ["--disableCaching"]
            cmd += ["--writeLogsFromAllJobs", "True"]
            cmd += ["--logFile", "full_log.log"]
            cmd += ["--writeLogs", os.environ["APPTAINERENV_LOGSDIR"]]
            cmd += ["--outdir", os.environ["APPTAINERENV_RESULTSDIR"]]
            cmd += ["--tmp-outdir-prefix", os.environ["APPTAINERENV_TMPDIR"]]
            cmd += ["--jobStore", os.path.join(self.rundir, "jobstore")]
            cmd += ["--workDir", workdir]
            cmd += ["--coordinationDir", dir_coordination]
            cmd += ["--tmpdir-prefix", os.environ["APPTAINERENV_TMPDIR"]]
            cmd += ["--disableAutoDeployment", "True"]
            cmd += ["--bypass-file-store"]
            cmd += [
                "--batchLogsDir",
                os.path.join(os.environ["APPTAINERENV_LOGSDIR"], dir_slurmlogs),
            ]
            cmd += ["--no-compute-checksum"]
            cmd += [
                os.path.join(
                    os.environ["VLBI_DATA_ROOT"], "workflows", f"{self.mode.value}.cwl"
                )
            ]
            cmd += [self.configfile]
            out = subprocess.check_output(cmd)

    def setup_apptainer_variables(self, workdir):
        out = (
            subprocess.check_output(["singularity", "--version"])
            .decode("utf-8")
            .strip()
        )
        if "apptainer" in out:
            os.environ["APPTAINERENV_VLBI_DATA_ROOT"] = os.environ["VLBI_DATA_ROOT"]
            os.environ["APPTAINERENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["APPTAINERENV_RESULTSDIR"] = (
                f"{workdir}/results_VLBI_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_LOGSDIR"] = (
                f"{workdir}/logs_VLBI_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_TMPDIR"] = (
                f"{workdir}/tmpdir_VLBI_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_PREPEND_PATH"] = (
                f"{os.environ['VLBI_DATA_ROOT']}/scripts:{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            os.mkdir(os.environ["APPTAINERENV_LOGSDIR"])
            os.mkdir(os.environ["APPTAINERENV_TMPDIR"])
            os.mkdir(os.environ["APPTAINERENV_RESULTSDIR"])
        elif "singularity" in out:
            os.environ["SINGULARITYENV_VLBI_DATA_ROOT"] = os.environ["VLBI_DATA_ROOT"]
            os.environ["SINGULARITYENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["SINGULARITYENV_RESULTSDIR"] = (
                f"{workdir}/results_VLBI_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_LOGSDIR"] = (
                f"{workdir}/logs_VLBI_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_TMPDIR"] = (
                f"{workdir}/tmpdir_VLBI_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_PREPEND_PATH"] = (
                f"{os.environ['VLBI_DATA_ROOT']}/scripts:{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            os.mkdir(os.environ["SINGULARITYENV_LOGSDIR"])
            os.mkdir(os.environ["SINGULARITYENV_TMPDIR"])
            os.mkdir(os.environ["SINGULARITYENV_RESULTSDIR"])
        os.environ["PYTHONPATH"] = "$LINC_DATA_ROOT/scripts:" + os.environ["PYTHONPATH"]
        os.environ["PYTHONPATH"] = "$VLBI_DATA_ROOT/scripts:" + os.environ["PYTHONPATH"]

    def setup_toil_directories(self, workdir: str) -> tuple[str, str]:
        dir_coordination = os.path.join(workdir, "coordination")
        try:
            os.mkdir(dir_coordination)
        except FileExistsError:
            print("Coordination directory already exists, not overwriting.")

        dir_slurmlogs = os.path.join(os.environ["APPTAINERENV_LOGSDIR"], "slurmlogs")
        try:
            os.mkdir(dir_slurmlogs)
        except FileExistsError:
            print("Slurm log directory already exists, not overwriting.")

        return (dir_coordination, dir_slurmlogs)


logger = structlog.getLogger()

if "LINC_DATA_ROOT" not in os.environ:
    logger.critical(
        "LINC_DATA_ROOT environment variable has not been set. This is needed for pipeline execution and generating $LINC_DATA_ROOT/.versions file."
    )
    sys.exit(-1)
app = typer.Typer(add_completion=False)


@app.command()
def delay_calibration(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    ms_suffix: Annotated[
        str, Option(help="Extension to look for when searching `mspath` for MSes.")
    ] = ".MS",
):
    pass


@app.command()
def split_direction(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
):
    pass


@app.command()
def setup(mspath: Annotated[str, Argument(help="Directory where MSes are located.")]):
    pass


@app.command()
def concatenate_flag(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
):
    pass


@app.command()
def phaseup_concat(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
):
    pass


if __name__ == "__main__":
    print("Hello")
    app()
