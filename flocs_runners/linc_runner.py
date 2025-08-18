from .utils import cwl_file, cwl_dir, LINCJSONConfig
import os
import sys
import structlog
import typer
from typer import Argument, Option
from typing import List, Optional, Tuple
from typing_extensions import Annotated

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
        str, Option(help="Path to the RFI flagging strategy to use with AOFlagger.")
    ] = os.path.join(
        os.environ["LINC_DATA_ROOT"], "rfistrategies", "lofar-default.lua"
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
    propagatesolutoins: Annotated[
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
    ATeam_skymodel: Annotated[
        Optional[str],
        Option(
            parser=cwl_file,
            metavar="SKYMODEL",
            help="File path to the A-Team skymodel.",
        ),
    ] = None,
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
):
    args = locals()
    logger.info("Generating LINC Calibrator config")
    config = LINCJSONConfig(
        args["mspath"],
        ms_suffix=args["ms_suffix"],
        update_version_file=args["update_version_file"],
    )
    args.pop("mspath")
    args.pop("update_version_file")
    for key, val in args.items():
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
            },
            workdir=args["rundir"],
        )


@app.command()
def target():
    pass


if __name__ == "__main__":
    app()
