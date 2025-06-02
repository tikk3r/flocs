import glob
import json
import os
import subprocess
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
