from .utils import (
    cwl_file,
    cwl_dir,
    add_apptainer_skeleton,
    add_slurm_skeleton,
    check_dd_freq,
    get_prefactor_freqs,
    setup_toil_slurm,
    verify_slurm_environment_toil,
    verify_toil,
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
    delay_calibrator: Annotated[
        str,
        typer.Option(
            parser=cwl_file, help="A delay calibrator catalogue in CSV format."
        ),
    ],
    configfile: Annotated[
        str,
        typer.Option(
            parser=cwl_file, help="Settings for the delay calibration in delay_solve."
        ),
    ],
    selfcal: Annotated[
        str, typer.Option(parser=cwl_dir, help="Path of external calibration scripts.")
    ],
    h5merger: Annotated[
        str,
        typer.Option(
            parser=cwl_dir, help="External LOFAR helper scripts for merging h5 files."
        ),
    ],
    linc: Annotated[
        str,
        typer.Option(
            parser=cwl_dir,
            help="The installation directory for the LOFAR INitial calibration pipeline.",
        ),
    ],
    ms_suffix: Annotated[
        str, Option(help="Extension to look for when searching `mspath` for MSes.")
    ] = ".MS",
    solset: Annotated[
        Optional[str],
        typer.Option(
            parser=cwl_file,
            help="The solution tables generated by the LINC target pipeline in an HDF5 format.",
        ),
    ] = None,
    filter_baselines: Annotated[
        Optional[str],
        typer.Option(
            help="The default filter constraints for the dp3_prep_target step."
        ),
    ] = "*&",
    flag_baselines: Annotated[
        Optional[List[str]],
        typer.Option(
            help="The baselines to be flagged by DP3. Can be a pattern, e.g. [ CS013HBA*&&* ]."
        ),
    ] = [],
    phasesol: Annotated[
        Optional[str],
        typer.Option(
            help="The name of the target solution table to use from the solset input."
        ),
    ] = "TGSSphase",
    reference_stationSB: Annotated[
        Optional[int],
        typer.Option(
            help="Subbands are concatenated in the concatenate-flag workflow relative to this station subband."
        ),
    ] = 104,
    number_cores: Annotated[
        Optional[int],
        typer.Option(
            help="Number of cores to use per job for tasks with high I/O or memory."
        ),
    ] = 12,
    max_dp3_threads: Annotated[
        Optional[int], typer.Option(help="The number of threads per DP3 process.")
    ] = 5,
    ddf_solsdir: Annotated[
        Optional[str],
        typer.Option(
            parser=cwl_dir,
            help="[Required if subtracting LoTSS] Path to the SOLSDIR directory of the DDF-pipeline run, where most of the calibration solutions are stored.",
        ),
    ] = None,
    ddf_rundir: Annotated[
        Optional[str],
        typer.Option(
            parser=cwl_dir,
            help="[Required if subtracting LoTSS] Path to the directory of the DDF-pipeline run where files required for the subtract can be found.",
        ),
    ] = None,
    box_size: Annotated[
        Optional[float],
        typer.Option(
            help="[Required if subtracting LoTSS] Box size, in degrees, outside of which to subtract the LoTSS model from the data."
        ),
    ] = 2.5,
    subtract_chunk_hours: Annotated[
        Optional[float],
        typer.Option(
            help="The range of time to predict the LoTSS model for at once. Lowering this value reduces memory footprint at the (possible) cost of increased runtime and vice versa."
        ),
    ] = 0.5,
    do_subtraction: Annotated[
        Optional[bool],
        typer.Option(
            help="When set to true, the LoTSS model will be subtracted from the DDF corrected data."
        ),
    ] = False,
):
    args = locals()
    logger.info("Generating VLBI delay-calibration config")
    config = VLBIJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "container",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_VLBI_delay-calibration.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
            },
            workdir=args["rundir"],
            container=args["container"],
        )


@app.command()
def split_direction(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    h5merger: Annotated[
        str, typer.Option(parser=cwl_dir, help="The h5merger directory.")
    ],
    selfcal: Annotated[
        str, typer.Option(parser=cwl_dir, help="The selfcal directory.")
    ],
    image_cat: Annotated[
        str,
        typer.Option(
            parser=cwl_file,
            help="The image catalogue (in FITS or CSV format) containing the target directions.",
        ),
    ] = "lotss_catalogue.csv",
    configfile: Annotated[
        Optional[str],
        typer.Option(
            parser=cwl_file,
            help="The configuration file to be used to run facetselfcal.py during the target_selfcal step.",
        ),
    ] = None,
    delay_solset: Annotated[
        Optional[str],
        typer.Option(
            parser=cwl_file,
            help="The solution tables generated by the VLBI delay calibration workflow in an HDF5 format.",
        ),
    ] = None,
    max_dp3_threads: Annotated[
        Optional[int],
        typer.Option(
            help="Number of cores to use per job for tasks with high I/O or memory."
        ),
    ] = 4,
    numbands: Annotated[
        Optional[int],
        typer.Option(help="The number of bands to group. -1 means all bands."),
    ] = -1,
    truncateLastSBs: Annotated[
        Optional[bool],
        typer.Option(
            help="Whether to truncate the last subbands of the MSs to the same length."
        ),
    ] = True,
    do_selfcal: Annotated[
        Optional[bool],
        typer.Option(help="Whether to do selfcal on the direction concat MSs."),
    ] = False,
    dd_selection: Annotated[
        Optional[bool],
        typer.Option(
            help="If set to true the pipeline will perform direction-dependent calibrator selection."
        ),
    ] = False,
    phasediff_score: Annotated[
        float,
        typer.Option(
            help="Phasediff-score for calibrator selection <2.3 good for DD-calibrators and <0.7 good for DI-calibrators. Only used when dd_selection==true."
        ),
    ] = 2.3,
    peak_flux_cut: Annotated[
        float,
        typer.Option(
            help="Peak flux (Jy/beam) cut to pre-select sources from catalogue. Default at 0.0 is no peak flux selection."
        ),
    ] = 0.0,
):
    args = locals()
    logger.info("Generating VLBI split-directions config")
    config = VLBIJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "container",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_VLBI_split-directions.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
            },
            workdir=args["rundir"],
            container=args["container"],
        )


@app.command()
def setup(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    solset: Annotated[
        str,
        typer.Option(
            parser=cwl_file,
            help="The solution tables generated by the LINC target pipeline in an HDF5 format.",
        ),
    ],
    linc: Annotated[
        str,
        typer.Option(
            parser=cwl_dir,
            help="The installation directory for the LOFAR INitial calibration pipeline.",
        ),
    ],
    filter_baselines: Annotated[
        Optional[str],
        typer.Option(
            help="The default filter constraints for the dp3_prep_target step."
        ),
    ] = "*&",
    flag_baselines: Annotated[
        Optional[List[str]],
        typer.Option(
            help="The baselines to be flagged by DP3. Can be a pattern, e.g. [ CS013HBA*&&* ]."
        ),
    ] = [],
    phasesol: Annotated[
        Optional[str],
        typer.Option(
            help="The name of the target solution table to use from the solset input."
        ),
    ] = "TGSSphase",
    min_separation: Annotated[
        Optional[int],
        typer.Option(
            help="The minimal accepted angular distance to an A-team source on the sky in degrees."
        ),
    ] = 30,
    number_cores: Annotated[
        Optional[int],
        typer.Option(
            help="The minimum number of cores that should be available for steps that require high I/O."
        ),
    ] = 12,
    max_dp3_threads: Annotated[
        Optional[int],
        typer.Option(help="The maximum number of threads DP3 should use per process."),
    ] = 5,
    clip_sources: Annotated[
        Optional[List[str]],
        typer.Option(
            help="The patches of sources that should be flagged. These should be present in the LINC skymodel."
        ),
    ] = ["VirA_4_patch", "CygAGG", "CasA_4_patch", "TauAGG"],
):
    args = locals()
    logger.info("Generating VLBI setup config")
    config = VLBIJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "container",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_VLBI_setup.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
            },
            workdir=args["rundir"],
            container=args["container"],
        )


@app.command()
def concatenate_flag(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    linc: Annotated[
        str,
        typer.Option(
            parser=cwl_dir,
            help="The installation directory for the LOFAR INitial Calibration pipeline.",
        ),
    ],
    numbands: Annotated[
        Optional[int],
        typer.Option(
            help="The number of files that have to be grouped together in frequency."
        ),
    ] = 10,
    firstSB: Annotated[
        Optional[int],
        typer.Option(
            help="If set, reference the grouping of files to this station subband."
        ),
    ] = None,
    max_dp3_threads: Annotated[
        Optional[int],
        typer.Option(
            help="The maximum number of threads that DP3 should use per process."
        ),
    ] = 5,
    aoflagger_memory_fraction: Annotated[
        Optional[int],
        typer.Option(
            help="The fraction of the node's memory that will be used by AOFlagger (and should be available before an AOFlagger job can start)."
        ),
    ] = 15,
):
    args = locals()
    logger.info("Generating VLBI concatenate-flag config")
    config = VLBIJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "container",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_VLBI_concatenate-flag.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
            },
            workdir=args["rundir"],
            container=args["container"],
        )


@app.command()
def phaseup_concat(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    delay_calibrator: Annotated[
        str,
        typer.Option(
            parser=cwl_file,
            help="Catalogue file with information on in-field calibrator.",
        ),
    ],
    configfile: Annotated[
        str,
        typer.Option(
            parser=cwl_file, help="Settings for the delay calibration in delay_solve."
        ),
    ],
    selfcal: Annotated[
        str, typer.Option(parser=cwl_dir, help="Path of external calibration scripts.")
    ],
    linc: Annotated[
        str,
        typer.Option(
            parser=cwl_dir,
            help="The installation directory for the LOFAR INitial calibration pipeline.",
        ),
    ],
    numbands: Annotated[
        Optional[int],
        typer.Option(help="The number of files that have to be grouped together."),
    ] = -1,
    firstSB: Annotated[
        Optional[int],
        typer.Option(
            help="If set, reference the grouping of files to this station subband."
        ),
    ] = None,
    max_dp3_threads: Annotated[
        Optional[int],
        typer.Option(help="The maximum number of threads DP3 should use per process."),
    ] = 5,
    number_cores: Annotated[
        Optional[int],
        typer.Option(
            help="Number of cores to use per job for tasks with high I/O or memory."
        ),
    ] = 12,
):
    args = locals()
    logger.info("Generating VLBI phaseup-concat config")
    config = VLBIJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "container",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_VLBI_phaseup-concat.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
            },
            workdir=args["rundir"],
            container=args["container"],
        )


if __name__ == "__main__":
    print("Hello")
    app()
