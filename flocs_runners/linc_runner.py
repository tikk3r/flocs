from .utils import (
    add_slurm_skeleton,
    check_dd_freq,
    cwl_file,
    cwl_dir,
    download_skymodel,
    extract_obsid_from_ms,
    get_prefactor_freqs,
    obtain_spinifex,
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
from time import gmtime, strftime
import typer
from enum import Enum
from typer import Argument, Option
from typing import List, Optional, Tuple
from typing_extensions import Annotated


class LINCJSONConfig:
    """Class for generating JSON configuration files to be passed to the LINC pipeline."""

    class OBS_TYPE(Enum):
        CALIBRATOR = "calibrator"
        TARGET = "target"

    def __init__(
        self,
        mspath: str,
        ms_suffix: str = ".MS",
        prefac_h5parm={"path": ""},
        update_version_file: bool = False,
    ):
        if "LINC_DATA_ROOT" not in os.environ:
            raise ValueError(
                "WARNING: LINC_DATA_ROOT environment variable has not been set. Cannot generate $LINC_DATA_ROOT/.versions file."
            )
            sys.exit(-1)
        self.configdict = {}

        filedir = os.path.join(mspath, f"*{ms_suffix}")
        logger.info(f"Searching {filedir}")
        files = sorted(glob.glob(filedir))
        logger.info(f"Found {len(files)} files")

        if not prefac_h5parm["path"]:
            mslist = []
            for ms in files:
                x = json.loads(f'{{"class": "Directory", "path":"{ms}"}}')
                mslist.append(x)
            self.configdict["msin"] = mslist
        elif not prefac_h5parm["path"].endswith("h5") and not prefac_h5parm[
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
        self.obsid = extract_obsid_from_ms(self.configdict["msin"][0]["path"])
        self.create_linc_versions_file(update_version_file)

    def add_entry(self, key: str, value: object):
        if "A_Team" in key:
            self.configdict["A-Team_skymodel"] = value
        else:
            self.configdict[key] = value

    def create_linc_versions_file(self, overwrite=False):
        if "LINC_DATA_ROOT" not in os.environ:
            raise ValueError(
                "WARNING: LINC_DATA_ROOT environment variable has not been set. Cannot generate $LINC_DATA_ROOT/.versions file."
            )
        linc_version = subprocess.check_output(
            f"cd {os.environ['LINC_DATA_ROOT']} && git describe --tags",
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
            self.rundir = tempfile.mkdtemp(
                prefix=f"tmp.LINC_calibrator_{self.obsid}.", dir=workdir
            )
        elif "target" in self.configfile:
            self.rundir = tempfile.mkdtemp(
                prefix=f"tmp.LINC_target_{self.obsid}.", dir=workdir
            )
        else:
            logger.warning("Unknown config file passed; exiting.")
            sys.exit(-1)

    def move_results_from_rundir(self):
        date = strftime("%Y_%m_%d-%H_%M_%S", gmtime())
        try:
            logger.info("Tarring log directory to reduce files")
            tarjob = subprocess.check_output(
                [
                    "tar",
                    "cf",
                    os.path.join(self.rundir, f"logs_LINC_{self.mode.value}.tar"),
                    os.path.join(self.rundir, f"logs_LINC_{self.mode.value}"),
                ]
            )
            logger.info("Removing log directory")
            subprocess.check_output(
                ["rm", "-r", os.path.join(self.rundir, f"logs_LINC_{self.mode.value}")]
            )
        except subprocess.CalledProcessError:
            logger.warning("Failed to tar logs.")
        try:
            logger.info("Removing leftover tmpdirs")
            tempdirs = glob.glob(os.path.join(self.rundir, "tmpdir*"))
            for td in tempdirs:
                subprocess.check_output(["rm", "-rf", td])
        except subprocess.CalledProcessError:
            logger.warning("Failed to remove leftover tmpdirs.")

        logger.info("Copying results")
        os.mkdir(f"LINC_{self.mode.value}_L{self.obsid}_{date}")
        globs = glob.glob(os.path.join(self.rundir, "*"))
        for f in globs:
            subprocess.check_output(
                [
                    "rsync",
                    "-avP",
                    f,
                    f"LINC_{self.mode.value}_L{self.obsid}_{date}",
                ]
            )

    def run_workflow(
        self,
        runner: str = "toil",
        scheduler: str = "slurm",
        workdir: str = os.getcwd(),
        container: str = "",
        slurm_params: dict = {},
        restart: bool = False,
        record_stats: bool = False,
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
        if not restart:
            self.setup_rundir(workdir)
            self.restarting = False
        else:
            self.rundir = workdir
            self.restarting = True
            logger.info(f"Attempting to restart existing workflow from {self.rundir}.")
        self.setup_apptainer_variables(self.rundir)
        logger.info(
            f"Running workflow with {runner} under {scheduler} in {self.rundir}"
        )

        if runner == "cwltool":
            cmd = (
                "cwltool "
                + "--parallel "
                + "--timestamps "
                + "--disable-pull "
                + "--singularity "
                + f"--tmpdir-prefix={os.environ['APPTAINERENV_TMPDIR']} "
                + f"--outdir={os.environ['APPTAINERENV_RESULTSDIR']} "
                + f"--log-dir={os.environ['APPTAINERENV_LOGSDIR']} "
            )
            cmd += (
                f"{os.environ['LINC_DATA_ROOT']}/workflows/HBA_{self.mode.value}.cwl "
            )
            cmd += f"{self.configfile}"

            if scheduler == "slurm":
                wrapped_cmd = add_slurm_skeleton(
                    contents=cmd,
                    job_name=f"LINC_{self.mode.value}",
                    **slurm_params,
                )
                with open("temp_jobscript.sh", "w") as f:
                    f.write(wrapped_cmd)
                logger.info("Written temporary jobscript to temp_jobscript.sh")
                out = subprocess.check_output(["sbatch", "temp_jobscript.sh"]).decode(
                    "utf-8"
                )
                print(out)
            elif scheduler == "singleMachine":
                logger.info(f"Running command:\n{cmd}")
                try:
                    out = subprocess.check_output(cmd.split(" "))
                    with open(f"log_LINC_{self.mode.value}.txt", "wb") as f:
                        f.write(out)
                    self.move_results_from_rundir()
                except subprocess.CalledProcessError as e:
                    with open(f"log_LINC_{self.mode.value}.txt", "wb") as f:
                        f.write(e.stdout)
                    if e.stderr:
                        with open(f"log_LINC_{self.mode.value}_err.txt", "wb") as f:
                            f.write(e.stderr)
        elif runner == "toil":
            verify_toil()
            verify_slurm_environment_toil()
            dir_coordination, dir_slurmlogs = self.setup_toil_directories(self.rundir)
            is_ceph = "ceph" in subprocess.check_output(
                ["df", self.rundir]
            ).lower().decode("utf-8")
            setup_toil_slurm(slurm_params)
            cmd = ["toil-cwl-runner"]
            if scheduler == "slurm":
                cmd += ["--batchSystem", "slurm"]
                cmd += ["--slurmTime", slurm_params["time"]]
                cmd += ["--slurmPartition", slurm_params["queue"]]
            elif scheduler == "singleMachine":
                cmd += ["--batchSystem", "singleMachine"]
            else:
                raise ValueError(f"Unsupported scheduler `{scheduler}` provided.")
            if self.restarting:
                cmd += ["--restart"]
            if "TOIL_SLURM_ARGS" in os.environ.keys():
                cmd += ["--slurmArgs", "'" + os.environ["TOIL_SLURM_ARGS"] + "'"]
            if record_stats:
                cmd += ["--stats"]
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
            if is_ceph:
                logger.info("Detected CEPH file system, not setting coordinationDir.")
                subprocess.check_output(["rm", "-r", dir_coordination])
            else:
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
                    os.environ["LINC_DATA_ROOT"],
                    "workflows",
                    f"HBA_{self.mode.value}.cwl",
                )
            ]
            cmd += [self.configfile]
            try:
                out = subprocess.check_output(cmd)
                with open(f"log_LINC_{self.mode.value}.txt", "wb") as f:
                    f.write(out)
                self.move_results_from_rundir()
            except subprocess.CalledProcessError as e:
                with open(f"log_LINC_{self.mode.value}.txt", "wb") as f:
                    f.write(e.stdout)
                if e.stderr:
                    with open(f"log_LINC_{self.mode.value}_err.txt", "wb") as f:
                        f.write(e.stderr)

    def setup_apptainer_variables(self, workdir):
        out = (
            subprocess.check_output(["singularity", "--version"])
            .decode("utf-8")
            .strip()
        )
        if "apptainer" in out:
            os.environ["APPTAINERENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["APPTAINERENV_RESULTSDIR"] = (
                f"{workdir}/results_LINC_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_LOGSDIR"] = (
                f"{workdir}/logs_LINC_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_TMPDIR"] = (
                f"{workdir}/tmpdir_LINC_{self.mode.value}/"
            )
            os.environ["APPTAINERENV_PREPEND_PATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            os.environ["APPTAINERENV_PYTHONPATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts:$PYTHONPATH"
            )
            if not self.restarting:
                os.mkdir(os.environ["APPTAINERENV_LOGSDIR"])
                os.mkdir(os.environ["APPTAINERENV_TMPDIR"])
                os.mkdir(os.environ["APPTAINERENV_RESULTSDIR"])
            os.environ["PATH"] = (
                os.environ["APPTAINERENV_PREPEND_PATH"] + ":" + os.environ["PATH"]
            )
        elif "singularity" in out:
            os.environ["SINGULARITYENV_LINC_DATA_ROOT"] = os.environ["LINC_DATA_ROOT"]
            os.environ["SINGULARITYENV_RESULTSDIR"] = (
                f"{workdir}/results_LINC_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_LOGSDIR"] = (
                f"{workdir}/logs_LINC_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_TMPDIR"] = (
                f"{workdir}/tmpdir_LINC_{self.mode.value}/"
            )
            os.environ["SINGULARITYENV_PREPEND_PATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts"
            )
            # Note that cwltool for some reason does not inherit this.
            os.environ["SINGULARITYENV_PYTHONPATH"] = (
                f"{os.environ['LINC_DATA_ROOT']}/scripts:$PYTHONPATH"
            )
            if not self.restarting:
                os.mkdir(os.environ["SINGULARITYENV_LOGSDIR"])
                os.mkdir(os.environ["SINGULARITYENV_TMPDIR"])
                os.mkdir(os.environ["SINGULARITYENV_RESULTSDIR"])
            os.environ["PATH"] = (
                os.environ["SINGULARITYENV_PREPEND_PATH"] + ":" + os.environ["PATH"]
            )
        if "PYTHONPATH" in os.environ:
            os.environ["PYTHONPATH"] = (
                "$LINC_DATA_ROOT/scripts:" + os.environ["PYTHONPATH"]
            )
        else:
            os.environ["PYTHONPATH"] = "$LINC_DATA_ROOT/scripts"

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
    logger.warning(
        "LINC_DATA_ROOT environment variable has not been set. Cannot generate $LINC_DATA_ROOT/.versions file."
    )
    sys.exit(-1)

app = typer.Typer(add_completion=False)


@app.command()
def calibrator(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    ms_suffix: Annotated[
        str, Option(help="Extension to look for when searching `mspath` for MSes.")
    ] = ".MS",
    save_raw_solutions: Annotated[
        bool,
        Option(
            help="Save the intermediate, raw solution tables for (bandpass, faraday, ion, polalign)."
        ),
    ] = False,
    update_version_file: Annotated[
        bool,
        Option(help="Overwrite the $LINC_DATA_ROOT/.versions file if it exists."),
    ] = False,
    refant: Annotated[
        str,
        Option(
            help="Regular expression of the statoins that are allowed to be selected as a reference antenna by the pipeline."
        ),
    ] = "CS00.*",
    # Silly workaround until typer starts supporting defaults for this type of input.
    flag_baselines: Annotated[
        Optional[List[str]],
        Option(
            help="DP3-compatible pattern for baselines or stations to be flagged (may  be an empty list).",
        ),
    ] = None,
    process_baselines_cal: Annotated[
        str,
        Option(
            help="Performs A-Team-clipping/demixing and direction-independent phase-only self-calibration only on these baselines. Choose [CR]S*& if you want to process only cross-correlations and remove international stations."
        ),
    ] = "*&",
    filter_baselines: Annotated[
        str,
        Option(
            help="Selects only this set of baselines to be processed. Choose [CR]S*& if you want to process only cross-correlations and remove international stations."
        ),
    ] = "*&",
    fit_offset_PA: Annotated[
        bool,
        Option(
            help="Assume that together with a delay each station also has a differential phase offset (important for old LBA observatoins)."
        ),
    ] = False,
    do_smooth: Annotated[
        bool, Option(help="Enable or disable baseline-based smoothing.")
    ] = False,
    rfistrategy: Annotated[
        str,
        Option(
            parser=cwl_file,
            help="Path to the RFI flagging strategy to use with AOFlagger.",
        ),
    ] = os.path.join(
        os.environ["LINC_DATA_ROOT"], "rfistrategies", "lofar-hba-wideband.lua"
    ),
    max2interpolate: Annotated[
        int,
        Option(
            help="Amount of channels in which interpolation should be performed for deriving the bandpass."
        ),
    ] = 30,
    ampRange: Annotated[
        Tuple[float, float],
        Option(help="Range of median amplitudes accepted per station."),
    ] = (0, 0),
    skip_international: Annotated[
        bool,
        Option(
            help="Skip fitting the bandpass for international stations (this avoids flagging them in many cases)."
        ),
    ] = True,
    raw_data: Annotated[
        bool, Option(help="Use autoweight. Set to True in case you are using raw data.")
    ] = False,
    propagatesolutions: Annotated[
        bool,
        Option(
            help="Use already derived solutions as initial guess for the upcoming timeslot."
        ),
    ] = True,
    flagunconverged: Annotated[
        bool,
        Option(
            help="Flag solutions for solves that did not converge (if they were also detected to diverge)."
        ),
    ] = False,
    maxStddev: Annotated[
        float,
        Option(
            help="Maximum allowable standard deviation when outlier clipping is done. For phases, this should value should be in radians, for amplitudes in log(amp). If None (or negative), a value of 0.1 rad is used for phases and 0.01 for amplitudes."
        ),
    ] = -1.0,
    solutions2transfer: Annotated[
        Optional[str],
        Option(
            metavar="H5PARM",
            parser=cwl_file,
            help="Provide own solutions from a reference calibrator observation in the case calibrator source is not trusted.",
        ),
    ] = "null",
    antennas2transfer: Annotated[
        str,
        Option(
            help="DP3-compatible baseline patterm for those stations wh should get calibration solutoins from a reference solution set in case calibrator source is not trusted."
        ),
    ] = "[FUSPID].*",
    do_transfer: Annotated[
        bool,
        Option(help="Enable solutions transfer for non-trusted calibrator sources."),
    ] = False,
    demix_sources: Annotated[List[str], Option(help="Sources to demix.")] = [
        "VirA_Gaussian",
        "CygA_Gaussian",
        "CasA_Gaussian",
        "TauA_Gaussian",
    ],
    demix_freqres: Annotated[
        str, Option(help="Frequency resolution used when demixing.")
    ] = "48.82kHz",
    demix_timeres: Annotated[
        float, Option(help="Time resolution used when demixing.")
    ] = 10.0,
    demix: Annotated[
        Optional[bool],
        Option(
            help="If true force demixing using all sources of demix_sources, if false do not demix (if null, automatically determines sources to be demixed according to min_separation)."
        ),
    ] = None,
    ion_3rd: Annotated[
        bool,
        Option(
            help="take into account also 3rd-order effects for the clock-TEC separation."
        ),
    ] = False,
    clock_smooth: Annotated[
        bool,
        Option(
            help="Only take the median of the derived clock solutions (enable this in case of non-joint observations)."
        ),
    ] = True,
    tables2export: Annotated[str, Option()] = "clock",
    max_dp3_threads: Annotated[
        int, Option(help="Number of threads per process for DP3.")
    ] = 10,
    memoryperc: Annotated[
        int,
        Option(
            help="Maximum of memory used for aoflagger in raw_flagging mode in percent."
        ),
    ] = 20,
    min_separation: Annotated[int, Option()] = 30,
    max_separation_arcmin: Annotated[
        float,
        Option(
            help="Maximum separation between phase center of the observation and the patch of a calibrator skymodel which is accepted to be chosen as a skymodel."
        ),
    ] = 1.0,
    calibrator_path_skymodel: Annotated[
        Optional[str],
        Option(
            parser=cwl_dir,
            metavar="DIRECTORY",
            help="Directory where calibrator skymodels are located.",
        ),
    ] = os.path.join(os.environ["LINC_DATA_ROOT"], "skymodels"),
    A_Team_skymodel: Annotated[
        Optional[str],
        Option(
            parser=cwl_file,
            metavar="SKYMODEL",
            help="File path to the A-Team skymodel.",
        ),
    ] = os.path.join(os.environ["LINC_DATA_ROOT"], "skymodels", "A-Team.skymodel"),
    avg_timeresolution: Annotated[
        int,
        Option(
            help="Intermediate time resolution of the data in seconds after averaging."
        ),
    ] = 4,
    avg_freqresolution: Annotated[
        str,
        Option(
            help="Intermediate frequency resolution of the data in seconds after averaging."
        ),
    ] = "48.82kHz",
    bandpass_freqresolution: Annotated[
        str, Option(help="Frequency resolution of the bandpass solution table.")
    ] = "195.3125kHz",
    lbfgs_historysize: Annotated[
        int,
        Option(
            help="For the LBFGS solver: the history size, specified as a multiple of the parameter vector, to use to approximate the inverse Hessian."
        ),
    ] = 10,
    lbfgs_robustdof: Annotated[
        int,
        Option(
            help="For the LBFGS solver: the degrees of freedom (DOF) given to the noise model."
        ),
    ] = 200,
    aoflag_reorder: Annotated[
        bool,
        Option(
            help="Make aoflagger reorder the measurement set before running the detection. This prevents that aoflagger will use its memory reading mode, which is faster but uses more memory."
        ),
    ] = False,
    aoflag_chunksize: Annotated[
        int,
        Option(
            help="Split the set into intervals with the given maximum size, and flag each interval independently. This lowers the amount of memory required."
        ),
    ] = 2000,
    solveralgorithm: Annotated[
        str, Option(help="Solver algorithm for DP3 to use.")
    ] = "directioniterative",
    config_only: Annotated[
        bool,
        Option(help="Only generate the config file, do not run it."),
    ] = False,
    scheduler: Annotated[
        str,
        Option(help="System scheduler to use."),
    ] = "singleMachine",
    runner: Annotated[
        str,
        Option(help="CWL runner to use."),
    ] = "cwltool",
    rundir: Annotated[
        str,
        Option(help="Directory to run in."),
    ] = os.getcwd(),
    slurm_queue: Annotated[
        str,
        Option(help="Slurm queue to run jobs on."),
    ] = "",
    slurm_account: Annotated[
        str,
        Option(help="Slurm account to use."),
    ] = "",
    slurm_time: Annotated[
        str,
        Option(help="Slurm time limit to use."),
    ] = "",
    slurm_cores: Annotated[
        int,
        Option(help="Number of cores to reserve for a monolithic pipeline run."),
    ] = 32,
    container: Annotated[
        str,
        Option(help="Apptainer container to use for cwltool runs."),
    ] = "",
    restart: Annotated[
        bool,
        Option(help="Restart a Toil workflow from the given rundir."),
    ] = False,
    record_toil_stats: Annotated[
        bool,
        Option(
            help="Use Toil's stats flag to record statistics. N.B. this disables cleanup of successful steps; make sure there is enough disk space until the end of the run."
        ),
    ] = False,
):
    args = locals()
    logger.info("Generating LINC Calibrator config")
    config = LINCJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    unneeded_keys = [
        "mspath",
        "ms_suffix",
        "update_version_file",
        "config_only",
        "scheduler",
        "runner",
        "rundir",
        "slurm_queue",
        "slurm_account",
        "slurm_time",
        "slurm_cores",
        "container",
        "restart",
        "record_toil_stats",
    ]
    args_for_linc = args.copy()
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_LINC_calibrator.json")
    if not args["config_only"]:
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
                "cores": args["slurm_cores"],
            },
            workdir=args["rundir"],
            container=args["container"],
            restart=args["restart"],
            record_stats=args["record_toil_stats"],
        )


@app.command()
def target(
    mspath: Annotated[str, Argument(help="Directory where MSes are located.")],
    cal_solutions: Annotated[
        str, typer.Argument(parser=cwl_file, help="Calibration solutions file.")
    ],
    ms_suffix: Annotated[
        str, Option(help="Extension to look for when searching `mspath` for MSes.")
    ] = ".MS",
    update_version_file: Annotated[
        bool,
        Option(help="Overwrite the $LINC_DATA_ROOT/.versions file if it exists."),
    ] = False,
    refant: Annotated[
        Optional[str], typer.Option(help="Reference antenna.")
    ] = "CS00.*",
    flag_baselines: Annotated[
        Optional[List[str]], typer.Option(help="Baselines to flag.")
    ] = [],
    process_baselines_target: Annotated[
        Optional[str], typer.Option(help="Target baselines to process.")
    ] = "[CR]S*&",
    filter_baselines: Annotated[
        Optional[str], typer.Option(help="Baselines to filter.")
    ] = "[CR]S*&",
    do_smooth: Annotated[
        Optional[bool], typer.Option(help="Enable smoothing.")
    ] = False,
    rfistrategy: Annotated[
        Optional[str], typer.Option(parser=cwl_file, help="RFI strategy file or name.")
    ] = os.path.join(
        f"{os.environ['LINC_DATA_ROOT']}", "rfistrategies", "lofar-hba-wideband.lua"
    ),
    min_unflagged_fraction: Annotated[
        Optional[float], typer.Option(help="Minimum unflagged fraction.")
    ] = 0.5,
    compression_bitrate: Annotated[
        Optional[int], typer.Option(help="Compression bitrate.")
    ] = 16,
    raw_data: Annotated[Optional[bool], typer.Option(help="Use raw data.")] = False,
    propagatesolutions: Annotated[
        Optional[bool], typer.Option(help="Propagate calibration solutions.")
    ] = True,
    maxStddev: Annotated[
        Optional[float], typer.Option(help="Maximum standard deviation.")
    ] = -1.0,
    demix_sources: Annotated[
        Optional[List[str]], typer.Option(help="Sources to demix.")
    ] = ["VirA_Gaussian", "CygA_Gaussian", "CasA_Gaussian", "TauA_Gaussian"],
    demix_timeres: Annotated[
        Optional[float], typer.Option(help="Demix time resolution.")
    ] = None,
    demix_freqres: Annotated[
        Optional[str], typer.Option(help="Demix frequency resolution.")
    ] = None,
    demix_maxiter: Annotated[
        Optional[int], typer.Option(help="Maximum demix iterations.")
    ] = None,
    demix: Annotated[Optional[bool], typer.Option(help="Enable demixing.")] = None,
    apply_tec: Annotated[
        Optional[bool], typer.Option(help="Apply TEC correction.")
    ] = False,
    apply_clock: Annotated[
        Optional[bool], typer.Option(help="Apply clock correction.")
    ] = True,
    apply_phase: Annotated[
        Optional[bool], typer.Option(help="Apply phase correction.")
    ] = False,
    apply_RM: Annotated[
        Optional[bool], typer.Option(help="Apply RM correction.")
    ] = True,
    get_RM: Annotated[Optional[bool], typer.Option(help="Estimate RM.")] = True,
    apply_beam: Annotated[
        Optional[bool], typer.Option(help="Apply beam correction.")
    ] = True,
    gsmcal_step: Annotated[
        Optional[str], typer.Option(help="GSM calibration step.")
    ] = "phase",
    updateweights: Annotated[
        Optional[bool], typer.Option(help="Update weights.")
    ] = True,
    max_dp3_threads: Annotated[
        Optional[int], typer.Option(help="Maximum DP3 threads.")
    ] = 10,
    memoryperc: Annotated[Optional[int], typer.Option(help="Memory percentage.")] = 20,
    min_separation: Annotated[
        Optional[int], typer.Option(help="Minimum separation.")
    ] = 30,
    min_probability: Annotated[
        Optional[float], typer.Option(help="Minimum probability.")
    ] = 0.5,
    A_Team_skymodel: Annotated[
        Optional[str],
        Option(
            parser=cwl_file,
            metavar="SKYMODEL",
            help="File path to the A-Team skymodel.",
        ),
    ] = os.path.join(os.environ["LINC_DATA_ROOT"], "skymodels", "A-Team.skymodel"),
    target_skymodel: Annotated[
        Optional[str], typer.Option(parser=cwl_file, help="Target sky model.")
    ] = None,
    use_target: Annotated[
        Optional[bool], typer.Option(help="Use target sky model.")
    ] = True,
    skymodel_source: Annotated[
        Optional[str], typer.Option(help="Skymodel source.")
    ] = "TGSS",
    avg_timeresolution: Annotated[
        Optional[int], typer.Option(help="Averaging time resolution.")
    ] = 4,
    avg_freqresolution: Annotated[
        Optional[str], typer.Option(help="Averaging frequency resolution.")
    ] = "48.82kHz",
    avg_timeresolution_concat: Annotated[
        Optional[int], typer.Option(help="Concat averaging time resolution.")
    ] = 8,
    avg_freqresolution_concat: Annotated[
        Optional[str], typer.Option(help="Concat averaging frequency resolution.")
    ] = "97.64kHz",
    num_SBs_per_group: Annotated[
        Optional[int], typer.Option(help="Number of SBs per group.")
    ] = None,
    calib_nchan: Annotated[
        Optional[int], typer.Option(help="Calibration channels.")
    ] = 1,
    reference_stationSB: Annotated[
        Optional[int], typer.Option(help="Reference station SB.")
    ] = None,
    clip_sources: Annotated[
        Optional[List[str]], typer.Option(help="Sources to clip.")
    ] = ["VirA_Gaussian", "CygA_Gaussian", "CasA_Gaussian", "TauA_Gaussian"],
    clipAteam: Annotated[
        Optional[bool], typer.Option(help="Clip A-Team sources.")
    ] = True,
    lbfgs_historysize: Annotated[
        Optional[int], typer.Option(help="LBFGS history size.")
    ] = None,
    lbfgs_robustdof: Annotated[
        Optional[float], typer.Option(help="LBFGS robust DOF.")
    ] = None,
    aoflag_reorder: Annotated[
        Optional[bool], typer.Option(help="Reorder AOFlagger.")
    ] = False,
    aoflag_chunksize: Annotated[
        Optional[int], typer.Option(help="AOFlagger chunk size.")
    ] = 2000,
    aoflag_freqconcat: Annotated[
        Optional[bool], typer.Option(help="AOFlagger frequency concatenation.")
    ] = True,
    selfcal: Annotated[
        Optional[bool], typer.Option(help="Enable self-calibration.")
    ] = False,
    selfcal_strategy: Annotated[
        Optional[str], typer.Option(help="Self-calibration strategy.")
    ] = "HBA",
    selfcal_hba_imsize: Annotated[
        Optional[List[int]], typer.Option(help="Selfcal HBA image size.")
    ] = [20000, 20000],
    hba_uvlambdamin: Annotated[
        Optional[float], typer.Option(help="HBA uv lambda minimum.")
    ] = 200.0,
    selfcal_region: Annotated[
        Optional[str], typer.Option(parser=cwl_file, help="Selfcal region file.")
    ] = None,
    chunkduration: Annotated[
        Optional[float], typer.Option(help="Chunk duration.")
    ] = 0.0,
    wsclean_tmpdir: Annotated[
        Optional[str], typer.Option(help="WSClean temporary directory.")
    ] = None,
    make_structure_plot: Annotated[
        Optional[bool], typer.Option(help="Make structure plot.")
    ] = False,
    skymodel_fluxlimit: Annotated[
        Optional[float], typer.Option(help="Skymodel flux limit.")
    ] = None,
    output_fullres_data: Annotated[
        Optional[bool], typer.Option(help="Output full-resolution data.")
    ] = False,
    solveralgorithm: Annotated[
        str, Option(help="Solver algorithm for DP3 to use.")
    ] = "directioniterative",
    config_only: Annotated[
        bool,
        Option(help="Only generate the config file, do not run it."),
    ] = False,
    scheduler: Annotated[
        str,
        Option(help="System scheduler to use."),
    ] = "singleMachine",
    runner: Annotated[
        str,
        Option(help="CWL runner to use."),
    ] = "cwltool",
    rundir: Annotated[
        str,
        Option(help="Directory to run in."),
    ] = os.getcwd(),
    slurm_queue: Annotated[
        str,
        Option(help="Slurm queue to run jobs on."),
    ] = "",
    slurm_account: Annotated[
        str,
        Option(help="Slurm account to use."),
    ] = "",
    slurm_time: Annotated[
        str,
        Option(help="Slurm time limit to use."),
    ] = "24:00:00",
    slurm_cores: Annotated[
        int,
        Option(help="Number of cores to reserve for a monolithic pipeline run."),
    ] = 32,
    container: Annotated[
        str,
        Option(help="Apptainer container to use for cwltool runs."),
    ] = "",
    offline_workers: Annotated[
        bool,
        Option(help="Indicates that the worker nodes do not have internet access."),
    ] = False,
    restart: Annotated[
        bool,
        Option(help="Restart a Toil workflow from the given rundir."),
    ] = False,
    record_toil_stats: Annotated[
        bool,
        Option(
            help="Use Toil's stats flag to record statistics. N.B. this disables cleanup of successful steps; make sure there is enough disk space until the end of the run."
        ),
    ] = False,
):
    args = locals()
    logger.info("Generating LINC Target config")
    config = LINCJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
        prefac_h5parm=cal_solutions,
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
        "slurm_cores",
        "container",
        "offline_workers",
        "restart",
        "record_toil_stats",
    ]
    args_for_linc = args.copy()
    if args_for_linc["output_fullres_data"]:
        logger.info("Full-resolution data requested, updating defaults to:")
        logger.info(f"avg_timeresolution: {args_for_linc['avg_timeresolution']} -> 1")
        logger.info(
            f"avg_freqresolution: {args_for_linc['avg_freqresolution']} -> 12.21kHz"
        )
        logger.info(f"filter_baselines: {args_for_linc['filter_baselines']} -> *&")

        args_for_linc["avg_timeresolution"] = 1
        args_for_linc["avg_freqresolution"] = "12.21kHz"
        args_for_linc["filter_baselines"] = "*&"
    for key in unneeded_keys:
        args_for_linc.pop(key)
    for key, val in args_for_linc.items():
        config.add_entry(key, val)
    config.save("mslist_LINC_target.json")
    if not args["config_only"]:
        if args["offline_workers"]:
            logger.info("Offline-worker mode requested")
            logger.info("Downloading spinifex corrections")
            new_h5 = obtain_spinifex(
                config.configdict["msin"][0]["path"], args["cal_solutions"]
            )
            args["cal_solutions"]["path"] = new_h5
            args["get_RM"] = False
            if not args["target_skymodel"]:
                logger.info("Downloading strating skymodel")
                model = download_skymodel(
                    config.configdict["msin"][0]["path"], output_dir=args["rundir"]
                )
                args["target_skymodel"]["path"] = model
        config.run_workflow(
            runner=args["runner"],
            scheduler=args["scheduler"],
            slurm_params={
                "queue": args["slurm_queue"],
                "account": args["slurm_account"],
                "time": args["slurm_time"],
                "cores": args["slurm_cores"],
            },
            workdir=args["rundir"],
            container=args["container"],
            restart=args["restart"],
            record_stats=args["record_toil_stats"],
        )


if __name__ == "__main__":
    app()
