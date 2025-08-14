import glob
import json
import os
import subprocess
import sys
import tempfile
from enum import Enum
from typing import Optional, Union

import casacore.tables as ct
import numpy as np
import structlog
from losoto.h5parm import h5parm

logger = structlog.getLogger()


def cwl_file(entry: str) -> Optional[str]:
    """Create a CWL-friendly file entry."""
    if entry is None:
        return None
    if entry.lower() == "null":
        return None
    else:
        return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')


def cwl_dir(entry: str) -> Optional[str]:
    """Create a CWL-friendly file entry."""
    if entry is None:
        return None
    if entry.lower() == "null":
        return None
    else:
        return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')


def check_dd_freq(infile: str, freq_array: Union[list, np.ndarray]) -> bool:
    """Check frequency coverage overlap between a Measurment Set and a given array of frequencies.

    Args:
        infile: input Measurement Set to check
        freq_array: array of frequencies to check against
    Returns:
        True if input frequencies are covered, False if input has frequencies that fall outside freq_array.
    """
    msfreqs = ct.table(("{:s}::SPECTRAL_WINDOW").format(infile))
    ref_freq = msfreqs.getcol("REF_FREQUENCY")[0]
    msfreqs.close()
    c = 0
    for f_arr in freq_array:
        if ref_freq > f_arr[0] and ref_freq < f_arr[1]:
            c = c + 1
        else:
            c = c + 0

    if c > 0:
        valid = True
    else:
        valid = False
    return valid


def get_dico_freqs(input_dir: str, solnames: str = "killMS.DIS2_full.sols.npz") -> list:
    """Extract frequencies from killMS format solutions.

    Args:
        input_dir: directory where the solutions are stored, usually called SOLSDIR.
        solnames: name of the solution files.
    Returns:
        freqs: array of frequencies covered by the solutions.
    """
    sol_dirs = glob.glob(os.path.join(input_dir, "L*pre-cal*.ms"))
    freqs = []
    for sol_dir in sol_dirs:
        npz_file = os.path.join(sol_dir, solnames)
        SolDico = np.load(npz_file)
        fmin = np.min(SolDico["FreqDomains"])
        fmax = np.max(SolDico["FreqDomains"])
        tmp_freqs = np.array([fmin, fmax])
        freqs.append(tmp_freqs)
        SolDico.close()

    return freqs


def get_prefactor_freqs(solname: str = "solutions.h5", solset: str = "target") -> list:
    """Extract frequency coverage from LINC solutions.

    Args:
        solname: name of the LINC solution file.
        solset: name of the solset to use.
    Returns:
        f_arr: array of frequencies covered by the solutions.
    """
    sols = h5parm(solname)
    ss = sols.getSolset(solset)
    st_names = ss.getSoltabNames()
    ph_sol_name = [xx for xx in st_names if "extract" not in xx][0]
    st = ss.getSoltab(ph_sol_name)
    freqs = st.getAxisValues("freq")
    freqstep = 1953125.0  ## the value for 10 subbands
    f_arr = []
    for xx in range(len(freqs)):
        fmin = freqs[xx] - freqstep / 2.0
        fmax = freqs[xx] + freqstep / 2.0
        f_arr.append(np.array([fmin, fmax]))
    sols.close()
    return f_arr


def get_reffreq(msfile: str) -> float:
    """Get the reference frequency of a Measurement Set.

    Args:
        msfile: input Measurement Set.
    """
    ss = ("taql 'select REF_FREQUENCY from {:s}::SPECTRAL_WINDOW' > tmp.txt").format(
        msfile
    )
    os.system(ss)
    with open("tmp.txt", "r") as (f):
        lines = f.readlines()
    f.close()
    os.system("rm tmp.txt")
    freq = float(lines[(-1)])
    return freq


class LINCJSONConfig:
    """Class for generating JSON configuration files to be passed to the LINC pipeline."""

    class OBS_TYPE(Enum):
        CALIBRATOR = 1
        TARGET = 2

    def __init__(
        self,
        mspath: str,
        ms_suffix: str = ".MS",
        prefac_h5parm={"path": ""},
        update_version_file: bool = False,
    ):
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
        if "calibrator" in self.configfile:
            self.rundir = tempfile.mkdtemp(prefix="tmp.LINC_calibrator.", dir=workdir)
        elif "target" in self.configfile:
            self.rundir = tempfile.mkdtemp(prefix="tmp.LINC_target.", dir=workdir)
        else:
            logger.warning("Unknown config file passed; exiting.")
            sys.exit(-1)

    def run_workflow(
        self,
        runner: str = "toil",
        scheduler: str = "slurm",
        workdir: str = os.getcwd(),
        container: str = "",
        slurm_params: dict = {},
    ):
        if self.configfile is None:
            raise RuntimeError("No config file has been created. Save it first.")
        elif "calibrator" in self.configfile:
            self.mode = self.OBS_TYPE.CALIBRATOR
        elif "target" in self.configfile:
            self.mode = self.OBS_TYPE.TARGET
        elif ("calibrator" not in self.configfile) and (
            "target" not in self.configfile
        ):
            raise RuntimeError(
                "Cannot deduce LINC workflow to run from config file name. Ensure either `calibrator` or `target` is present in the file name."
            )
        else:
            raise RuntimeError("Something unexpected went wrong with the config file.")
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
            if self.mode is self.OBS_TYPE.CALIBRATOR:
                cmd += f"{os.environ['LINC_DATA_ROOT']}/workflows/HBA_calibrator.cwl "
            elif self.mode is self.OBS_TYPE.TARGET:
                cmd += f"{os.environ['LINC_DATA_ROOT']}/workflows/HBA_target.cwl "
            cmd += f"{self.configfile}"

            if scheduler == "slurm":
                wrapped_cmd = add_slurm_skeleton(
                    contents=cmd,
                    time="24:00:00",
                    cores=32,
                    job_name="LINC_Calibrator",
                    *slurm_params,
                )
                print(wrapped_cmd)
                out = subprocess.check_output(["sbatch", wrapped_cmd]).decode("utf-8")
            elif scheduler == "singleMachine":
                if container:
                    cmd = add_apptainer_skeleton(contents=cmd, container=container)
                logger.info(f"Running command:\n{cmd}")
                out = subprocess.check_output(cmd.split(" ")).decode("utf-8")
                print(out)
        elif runner == "toil":
            dir_jobstore, dir_coordination, dir_slurmlogs = self.setup_toil_directories(
                workdir
            )
            self.setup_toil_slurm(slurm_params)
            cmd = ["toil-cwl-runner"]
            if scheduler == "slurm":
                cmd += ["--batchSystem", "slurm"]
            elif scheduler == "singleMachine":
                cmd += ["--batchSystem", "singleMachine"]
            else:
                raise ValueError(f"Unsupported scheduler `{scheduler}` provided.")
            cmd += ["--no-read-only"]
            cmd += ["--retryCount 3"]
            cmd += ["--singularity"]
            cmd += ["--disableCaching"]
            cmd += ["--writeLogsFromAllJobs True"]
            cmd += ["--logFile full_log.log"]
            cmd += ["--writeLogs ${LOGSDIR}"]
            cmd += ["--outdir ${RESULTSDIR}"]
            cmd += ["--tmp-outdir-prefix", os.environ["APPTAINERENV_TMPDIR"]]
            cmd += ["--jobStore", dir_jobstore]
            cmd += ["--workDir", workdir]
            cmd += ["--coordinationDir", dir_coordination]
            cmd += ["--tmpdir-prefix", os.environ["APPTAINERENV_TMPDIR"]]
            cmd += ["--disableAutoDeployment", "True"]
            cmd += ["--bypass-file-store"]
            cmd += ["--batchSystem slurm"]
            cmd += [
                "--batchLogsDir",
                os.path.join(os.environ["APPTAINERENV_LOGSDIR"], dir_slurmlogs),
            ]
            cmd += ["--no-compute-checksum"]
            if self.mode is self.OBS_TYPE.CALIBRATOR:
                cmd += [
                    os.path.join(
                        os.environ["LINC_DATA_ROOT"], "workflows", "HBA_calibrator.cwl"
                    )
                ]
            elif self.mode is self.OBS_TYPE.TARGET:
                cmd += [
                    os.path.join(
                        os.environ["LINC_DATA_ROOT"], "workflows", "HBA_target.cwl"
                    )
                ]
            cmd += [self.configfile]
        # logger.info(out)

    def setup_apptainer_variables(self, workdir):
        out = (
            subprocess.check_output(["singularity", "--version"])
            .decode("utf-8")
            .strip()
        )
        if "apptainer" in out:
            os.environ["APPTAINERENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["APPTAINERENV_RESULTSDIR"] = (
                f"{workdir}/results_LINC_calibrator/"
            )
            os.environ["APPTAINERENV_LOGSDIR"] = f"{workdir}/logs_LINC_calibrator/"
            os.environ["APPTAINERENV_TMPDIR"] = f"{workdir}/tmpdir_LINC_calibrator/"
            os.environ["APPTAINERENV_PREPEND_PATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            os.mkdir(os.environ["APPTAINERENV_LOGSDIR"])
            os.mkdir(os.environ["APPTAINERENV_TMPDIR"])
            os.mkdir(os.environ["APPTAINERENV_RESULTSDIR"])
        elif "singularity" in out:
            os.environ["SINGULARITYENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["SINGULARITYENV_RESULTSDIR"] = (
                f"{workdir}/results_LINC_calibrator/"
            )
            os.environ["SINGULARITYENV_LOGSDIR"] = f"{workdir}/logs_LINC_calibrator/"
            os.environ["SINGULARITYENV_TMPDIR"] = f"{workdir}/tmpdir_LINC_calibrator/"
            os.environ["SINGULARITYENV_PREPEND_PATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            os.mkdir(os.environ["SINGULARITYENV_LOGSDIR"])
            os.mkdir(os.environ["SINGULARITYENV_TMPDIR"])
            os.mkdir(os.environ["SINGULARITYENV_RESULTSDIR"])
        os.environ["PYTHONPATH"] = "$LINC_DATA_ROOT/scripts:" + os.environ["PYTHONPATH"]

    def setup_toil_directories(self, workdir: str) -> tuple[str, str, str]:
        dir_jobstore = os.path.join(workdir, "jobstore")
        try:
            os.mkdir(dir_jobstore)
        except FileExistsError:
            print("Jobstore directory already exists, not overwriting.")

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

        return (dir_jobstore, dir_coordination, dir_slurmlogs)

    def setup_toil_slurm(self, slurm_params: dict):
        """Sets the TOIL_SLURM_ARGS environment variable with information for the Slurm scheduler.

        It will always set to export all variables and adds SLURM details such as accounts and partitions if specified.

        Args:
            slurm_params (dict[str]): dictionary with slurm options. Accepted keys are `account` and `queue`.
        """
        os.environ["TOIL_SLURM_ARGS"] = "--export=ALL "
        if "queue" in slurm_params:
            os.environ["TOIL_SLURM_ARGS"] += f"-p {slurm_params["queue"]}"
        if "account" in slurm_params:
            os.environ["TOIL_SLURM_ARGS"] += f"-A {slurm_params["account"]}"


def add_slurm_skeleton(
    contents: str, time=None, cores=None, job_name=None, queue=None, account=None
):
    sbatch_line = "#SBATCH "
    if time:
        sbatch_line += f"-t {time}"
    if cores:
        sbatch_line += f"-c {cores}"
    if job_name:
        sbatch_line += f"--job-name {job_name}"
    if queue:
        sbatch_line += f"-p {queue}"
    if account:
        sbatch_line += f"-A {account}"
    wrapped = f"""#!/bin/bash
{sbatch_line}
{contents}
"""
    return wrapped


def add_apptainer_skeleton(contents: str, container: str, bindpaths: str = ""):
    wrapped = f"""apptainer exec -B {bindpaths} {container} {contents}"""
    return wrapped
