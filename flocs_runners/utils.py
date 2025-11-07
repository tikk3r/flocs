import glob
import json
import os
import subprocess
import sys
from packaging.version import Version
from pathlib import Path
from subprocess import CalledProcessError
from typing import Optional, Union

import casacore.tables as ct
import numpy as np
import spinifex
from spinifex import h5parm_tools
from spinifex.vis_tools import ms_tools
import structlog
from losoto.h5parm import h5parm

logger = structlog.getLogger()


def extract_obsid_from_ms(ms: str) -> str:
    inms = os.path.abspath(ms.rstrip())
    obsid = ct.taql(f"select LOFAR_OBSERVATION_ID from {inms}::OBSERVATION").getcol(
        "LOFAR_OBSERVATION_ID"
    )[0]
    return str(int(obsid) + 2).zfill(len(obsid))


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
        return json.loads(
            f'{{"class": "Directory", "path":"{os.path.abspath(entry)}"}}'
        )


def check_dd_freq(msin: str, freq_array: Union[list, np.ndarray]) -> bool:
    """Check frequency coverage overlap between a Measurment Set and a given array of frequencies.

    Args:
        msin: input Measurement Set to check
        freq_array: array of frequencies to check against
    Returns:
        True if input frequencies are covered, False if input has frequencies that fall outside freq_array.
    """
    msfreqs = ct.table(f"{msin.rstrip('/')}::SPECTRAL_WINDOW")
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


def setup_toil_slurm(slurm_params: dict):
    """Sets the TOIL_SLURM_ARGS environment variable with information for the Slurm scheduler.

    It will always set to export all variables and adds SLURM details such as accounts and partitions if specified.

    Args:
        slurm_params (dict[str]): dictionary with slurm options. Accepted keys are `account`, `queue` and `time`.
    """
    os.environ["TOIL_SLURM_ARGS"] = "--export=ALL "
    if "account" in slurm_params:
        os.environ["TOIL_SLURM_ARGS"] += f"-A {slurm_params['account']} "
        os.environ["SLURM_ACCOUNT"] = slurm_params["account"]
        os.environ["SBATCH_ACCOUNT"] = slurm_params["account"]


def verify_toil():
    try:
        toil_version = Version(
            subprocess.check_output(["toil-cwl-runner", "--version"]).decode("utf-8")
        )
        if toil_version < Version("9.0.0"):
            logger.critical(
                f"Flocs requires Toil 9 or newer, but found {toil_version}."
            )
            sys.exit(-1)
    except CalledProcessError:
        logger.critical("Toil does not seem to be installed.")
        sys.exit(-1)


def verify_slurm_environment_toil():
    failed = False
    if "CWL_SINGULARITY_CACHE" not in os.environ:
        logger.critical(
            "CWL_SINGULARITY_CACHE not found in the environment. Ensure it is set to where you have stored `astronrd_linc_latest.sif`."
        )
        failed = True
    elif not os.path.isfile(
        os.path.join(os.environ["CWL_SINGULARITY_CACHE"], "astronrd_linc_latest.sif")
    ):
        raise FileNotFoundError(
            "Cannot find astornrd_linc_latest.sif in CWL_SINGULARITY_CACHE."
        )
    if "APPTAINER_PULLDIR" not in os.environ:
        logger.critical(
            "APPTAINER_PULLDIR not found in the environment. Ensure it is set to where you have stored `astronrd_linc_latest.sif`."
        )
        failed = True
    elif not os.path.isfile(
        os.path.join(os.environ["APPTAINER_PULLDIR"], "astronrd_linc_latest.sif")
    ):
        raise FileNotFoundError(
            "Cannot find astornrd_linc_latest.sif in APPTAINER_PULLDIR."
        )
    if "APPTAINER_CACHEDIR" not in os.environ:
        logger.critical(
            "APPTAINER_CACHEDIR not found in the environment. Ensure it is set to where you have stored `astronrd_linc_latest.sif`."
        )
        failed = True
    elif not os.path.isfile(
        os.path.join(os.environ["APPTAINER_CACHEDIR"], "astronrd_linc_latest.sif")
    ):
        raise FileNotFoundError(
            "Cannot find astornrd_linc_latest.sif in APPTAINER_CACHEDIR."
        )
    if failed:
        raise RuntimeError("One or more critical environment variables were not set.")


def add_slurm_skeleton(
    contents: str, time=None, cores=None, job_name=None, queue=None, account=None
):
    sbatch_line = "#SBATCH "
    if time:
        sbatch_line += f"-t {time} "
    if cores:
        sbatch_line += f"-c {cores} "
    if job_name:
        sbatch_line += f"--job-name {job_name} "
    if queue:
        sbatch_line += f"-p {queue} "
    if account:
        sbatch_line += f"-A {account} "
    wrapped = f"""#!/bin/bash
{sbatch_line}
{contents}
"""
    return wrapped


def add_apptainer_skeleton(contents: str, container: str, bindpaths: str = ""):
    wrapped = f"apptainer exec -B {bindpaths} {container} {contents}"
    return wrapped


def obtain_spinifex(ms: str, h5parm: str, backup: bool = True) -> str:
    if backup:
        os.system(f"cp {h5parm} {h5parm.replace('.h5', '_spinifex.h5')}")
        h5parm = h5parm.replace(".h5", "_spinifex.h5")
        logger.info(f"Working on copy {h5parm}")
    ms_metadata = ms_tools.get_metadata_from_ms(Path(ms))
    rm = ms_tools.get_rm_from_ms(Path(ms), use_stations=ms_metadata.station_names)
    h5parm_tools.write_rm_to_h5parm(rms=rm, h5parm_name=h5parm)
    return os.path.abspath(h5parm)


def download_skymodel(
    ms: str, survey: str = "TGSS", output_dir: str = os.getcwd()
) -> str:
    tab = ct.table(f"{ms}::POINTING")
    name = tab.getcol("NAME")[0]
    filename = os.path.abspath(f"skymodel_LINC_{name}.txt")
    subprocess.run(
        f"download_skymodel_target.py --Radius 5 --Source {survey} --targetname {name} {os.path.abspath(ms)} {os.path.join(output_dir, filename)}",
        shell=True,
    )
    return filename
