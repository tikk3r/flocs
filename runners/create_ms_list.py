import argparse
import glob
import json
import os
import sys

import casacore.tables as ct
import numpy as np
from losoto.h5parm import h5parm

from typing import Union


def add_arguments_linc_calibrator(parser: argparse.ArgumentParser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--refant",
        type=str,
        default="CS00.*",
        help="Regular expression of the stations that are allowed to be selected as a reference antenna by the pipeline.",
    )
    parser.add_argument(
        "--flag_baselines",
        type=str,
        nargs="*",
        default=[],
        help="DP3-compatible pattern for baselines or stations to be flagged (may be an empty list.",
    )
    parser.add_argument(
        "--process_baselines_cal",
        type=str,
        default="*&",
        help="Performs A-Team-clipping/demixing and direction-independent phase-only self-calibration only on these baselines. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.",
    )
    parser.add_argument(
        "--filter_baselines",
        type=str,
        default=None,
        help="Selects only this set of baselines to be processed. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.",
    )
    parser.add_argument(
        "--fit_offset_PA",
        type=bool,
        default=False,
        help="Assume that together with a delay each station has also a differential phase offset (important for old LBA observations).",
    )
    parser.add_argument(
        "--do_smooth",
        type=bool,
        default=False,
        help="Enable or disable baseline-based smoothing.",
    )
    parser.add_argument(
        "--rfi_strategy",
        type=str,
        default=os.path.join(
            os.environ["LINC_DATA_ROOT"], "rfistrategies", "lofar-default.lua"
        ),
        help="Path to the RFI flagging strategy to use with AOFlagger.",
    )
    parser.add_argument(
        "--max2interpolate",
        type=int,
        default=30,
        help="Amount of channels in which interpolation should be performed for deriving the bandpass.",
    )
    parser.add_argument(
        "--ampRange",
        type=float,
        nargs="*",
        default=[0, 0],
        help="Range of median amplitudes accepted per station.",
    )
    parser.add_argument(
        "--skip_international",
        type=bool,
        default=True,
        help="Skip fitting the bandpass for international stations (this avoids flagging them in many cases).",
    )
    parser.add_argument(
        "--raw_data",
        type=bool,
        default=False,
        help="Use autoweight. Set to True in case you are using raw data.",
    )
    parser.add_argument(
        "--propagatesolutions",
        type=bool,
        default=True,
        help="Use already derived solutions as initial guess for the upcoming time slot.",
    )
    parser.add_argument(
        "--flagunconverged",
        type=bool,
        default=False,
        help="Flag solutions for solves that did not converge (if they were also detected to diverge).",
    )
    parser.add_argument(
        "--masStddev",
        type=float,
        default=-1.0,
        help="Maximum allowable standard deviation when outlier clipping is done. For phases, this should value should be in radians, for amplitudes in log(amp). If None (or negative), a value of 0.1 rad is used for phases and 0.01 for amplitudes.",
    )
    parser.add_argument(
        "--solutions2transfer",
        type=cwl_file,
        default="null",
        help="Provide own solutions from a reference calibrator observation in case calibrator source is not trusted.",
    )
    parser.add_argument(
        "--antennas2transfer",
        type=str,
        default="[FUSPID].*",
        help="DP3-compatible baseline pattern for those stations who should get calibration solutions from a reference solution set in case calibrator source is not trusted.",
    )
    parser.add_argument(
        "--do_transfer",
        type=bool,
        default=False,
        help="Enable solutions transfer for non-trusted calibrator sources.",
    )
    parser.add_argument(
        "--trusted_sources",
        type=str,
        default="3C48,3C147,3C196,3C295,3C380",
        help="Comma-separated list of trusted calibrator sources. Solutions are only transferred from a reference solution set in case the observed calibrator is not among them.",
    )
    parser.add_argument(
        "--demix_sources",
        type=str,
        nargs="*",
        default=["CasA", "CygA"],
        help="Sources to demix.",
    )
    parser.add_argument(
        "--demix_freqres",
        type=str,
        default="48.82kHz",
        help="Frequency resolution used when demixing.",
    )
    parser.add_argument(
        "--demix_timeres",
        type=float,
        default=10,
        help="Frequency resolution used when demixing.",
    )
    parser.add_argument(
        "--demix",
        type=str,
        default=None,
        help="If true force demixing using all sources of demix_sources, if false do not demix (if null, automatically determines sources to be demixed according to min_separation).",
    )
    parser.add_argument(
        "--ion_3rd",
        type=bool,
        default=False,
        help="Take into account also 3rd-order effects for the clock-TEC separation.",
    )
    parser.add_argument(
        "--clock_smooth",
        type=bool,
        default=True,
        help="Only take the median of the derived clock solutions (enable this in case of non-joint observations).",
    )
    parser.add_argument("--tables2export", type=str, default="clock")
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=10,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--memoryperc",
        type=int,
        default=20,
        help="Maximum of memory used for aoflagger in raw_flagging mode in percent.",
    )
    parser.add_argument(
        "--min_separation",
        type=int,
        default=30,
        help="",
    )
    parser.add_argument(
        "--max_separation_arcmin",
        type=float,
        default=1.0,
        help="Maximum separation between phase center of the observation and the patch of a calibrator skymodel which is accepted to be chosen as a skymodel.",
    )
    parser.add_argument(
        "--calibrator_path_skymodel",
        type=cwl_dir,
        default=os.path.join(os.environ["LINC_DATA_ROOT"], "skymodels"),
        help="Directory where calibrator skymodels are located.",
    )
    parser.add_argument(
        "--ATeam_skymodel",
        type=cwl_file,
        default=None,
        help="File path to the A-Team skymodel.",
    )
    parser.add_argument(
        "--avg_timeresolution",
        type=float,
        default=4,
        help="Intermediate time resolution of the data in seconds after averaging.",
    )
    parser.add_argument(
        "--avg_freqresolution",
        type=str,
        default="48.82kHz",
        help="Intermediate frequency resolution of the data after averaging.",
    )
    parser.add_argument(
        "--bandpass_freqresolution",
        type=str,
        default="195.3125kHz",
        help="Frequency resolution of the bandpass solution table.",
    )
    parser.add_argument(
        "--lbfgs_historysize",
        type=int,
        default=10,
        help="For the LBFGS solver: the history size, specified as a multiple of the parameter vector, to use to approximate the inverse Hessian.",
    )
    parser.add_argument(
        "--lbfgs_robustdof",
        type=int,
        default=200,
        help="For the LBFGS solver: the degrees of freedom (DOF) given to the noise model.",
    )
    parser.add_argument(
        "--aoflag_reorder",
        type=bool,
        default=False,
        help="Make aoflagger reorder the measurement set before running the detection. This prevents that aoflagger will use its memory reading mode, which is faster but uses more memory.",
    )
    parser.add_argument(
        "--aoflag_chunksize",
        type=int,
        default=2000,
        help="Split the set into intervals with the given maximum size, and flag each interval independently. This lowers the amount of memory required.",
    )


def add_arguments_linc_target(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--cal_solutions",
        type=cwl_file,
        default="",
        help="Path to the final LINC calibrator solution file.",
    )
    parser.add_argument(
        "--refant",
        type=str,
        default="CS00.*",
        help="Regular expression of the stations that are allowed to be selected as a reference antenna by the pipeline.",
    )
    parser.add_argument(
        "--flag_baselines",
        type=str,
        nargs="*",
        default=[],
        help="DP3-compatible pattern for baselines or stations to be flagged (may be an empty list.",
    )
    parser.add_argument(
        "--process_baselines_target",
        type=str,
        default="[CR]S*&",
        help="Performs A-Team-clipping/demixing and direction-independent phase-only self-calibration only on these baselines. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.",
    )
    parser.add_argument(
        "--filter_baselines",
        type=str,
        default="[CR]S*&",
        help="Selects only this set of baselines to be processed. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.",
    )
    parser.add_argument(
        "--do_smooth",
        type=bool,
        default=False,
        help="Enable or disable baseline-based smoothing.",
    )
    parser.add_argument(
        "--rfi_strategy",
        type=str,
        default=os.path.join(
            os.environ["LINC_DATA_ROOT"], "rfistrategies", "lofar-default.lua"
        ),
        help="Path to the RFI flagging strategy to use with AOFlagger.",
    )
    parser.add_argument(
        "--min_unflagged_fraction",
        type=float,
        default=0.5,
        help="Minimal fraction of unflagged data to be accepted for further processing of the data chunk",
    )
    parser.add_argument(
        "--compression_bitrate",
        type=int,
        default=16,
        help="Minimal fraction of unflagged data to be accepted for further processing of the data chunk.",
    )
    parser.add_argument(
        "--raw_data",
        type=bool,
        default=False,
        help="Use autoweight. Set to True in case you are using raw data.",
    )
    parser.add_argument(
        "--propagatesolutions",
        type=bool,
        default=True,
        help="Use already derived solutions as initial guess for the upcoming time slot.",
    )
    parser.add_argument(
        "--demix_sources",
        type=str,
        nargs="*",
        default=["CasA", "CygA"],
        help="Sources to demix.",
    )
    parser.add_argument(
        "--demix_freqres",
        type=str,
        default="48.82kHz",
        help="Frequency resolution used when demixing.",
    )
    parser.add_argument(
        "--demix_timeres",
        type=float,
        default=10,
        help="Frequency resolution used when demixing.",
    )
    parser.add_argument(
        "--demix",
        type=str,
        default=None,
        help="If true force demixing using all sources of demix_sources, if false do not demix (if null, automatically determines sources to be demixed according to min_separation).",
    )
    parser.add_argument(
        "--apply_tec",
        type=bool,
        default=False,
        help="Apply TEC solutions from the calibrator.",
    )
    parser.add_argument(
        "--apply_clock",
        type=bool,
        default=True,
        help="Apply clock solutions from the calibrator.",
    )
    parser.add_argument(
        "--apply_phase",
        type=bool,
        default=False,
        help="Apply full phase solutions from the calibrator.",
    )
    parser.add_argument(
        "--apply_RM",
        type=bool,
        default=True,
        help="Apply ionospheric Rotation Measure from RMextract.",
    )
    parser.add_argument(
        "--apply_beam",
        type=bool,
        default=True,
        help="Apply element beam corrections.",
    )
    parser.add_argument(
        "--gsmcal_step",
        type=str,
        default="phase",
        help="Type of calibration to be performed in the self-calibration step",
    )
    parser.add_argument(
        "--updateweights",
        type=bool,
        default=True,
        help="Update WEIGHT_SPECTRUM column in a way consistent with the weights being inverse proportional to the autocorrelations.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=10,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--memoryperc",
        type=int,
        default=20,
        help="Maximum of memory used for aoflagger in raw_flagging mode in percent.",
    )
    parser.add_argument(
        "--min_separation",
        type=int,
        default=30,
        help="",
    )
    parser.add_argument(
        "--ATeam_skymodel",
        type=cwl_file,
        default=None,
        help="File path to the A-Team skymodel.",
    )
    parser.add_argument(
        "--target_skymodel",
        type=cwl_file,
        default=None,
        help="",
    )
    parser.add_argument(
        "--use_target",
        type=bool,
        default=True,
        help="Enable downloading of a target skymodel.",
    )
    parser.add_argument(
        "--skymodel_source",
        type=str,
        default="TGSS",
        help="Choose the target skymodel from TGSS ADR (TGSS) or the new Global Sky Model (GSM).",
    )
    parser.add_argument(
        "--avg_timeresolution",
        type=float,
        default=4,
        help="Intermediate time resolution of the data in seconds after averaging.",
    )
    parser.add_argument(
        "--avg_timeresolution_concat",
        type=float,
        default=8,
        help="Final time resolution of the data in seconds after averaging and concatenation.",
    )
    parser.add_argument(
        "--avg_freqresolution",
        type=str,
        default="48.82kHz",
        help="Intermediate frequency resolution of the data after averaging.",
    )
    parser.add_argument(
        "--avg_freqresolution_concat",
        type=str,
        default="97.64kHz",
        help="Final frequency resolution of the data after averaging and concatenation.",
    )
    parser.add_argument(
        "--num_SBs_per_group",
        type=int,
        default=10,
        help="Make concatenated MeasurementSets of the specified number of subbands. Choose -1 to concatenate all.",
    )
    parser.add_argument("--reference_stationSB", type=int, default=None, help="")
    parser.add_argument(
        "--ionex_server", type=str, default="http://ftp.aiub.unibe.ch/CODE/", help=""
    )
    parser.add_argument("--ionex_prefix", type=str, default="CODG", help="")
    parser.add_argument("--proxy_server", type=str, default=None, help="")
    parser.add_argument("--proxy_port", type=int, default=None, help="")
    parser.add_argument("--proxy_type", type=str, default=None, help="")
    parser.add_argument("--proxy_pass", type=str, default=None, help="")
    parser.add_argument(
        "--clip_sources",
        type=str,
        nargs="*",
        default=["VirA_4_patch", "CygAGG", "CasA_4_patch", "TauAGG"],
        help="",
    )
    parser.add_argument("--clipAteam", type=bool, default=True, help="")
    parser.add_argument(
        "--lbfgs_historysize",
        type=int,
        default=10,
        help="For the LBFGS solver: the history size, specified as a multiple of the parameter vector, to use to approximate the inverse Hessian.",
    )
    parser.add_argument(
        "--lbfgs_robustdof",
        type=int,
        default=200,
        help="For the LBFGS solver: the degrees of freedom (DOF) given to the noise model.",
    )
    parser.add_argument(
        "--aoflag_chunksize",
        type=int,
        default=2000,
        help="Split the set into intervals with the given maximum size, and flag each interval independently. This lowers the amount of memory required.",
    )
    parser.add_argument(
        "--aoflag_freqconcat",
        type=bool,
        default=True,
        help="Concatenate all subbands on-the-fly before performing flagging. Disable if you use time-chunked input data.",
    )
    parser.add_argument("--chunkduration", type=float, default=0.0, help="")
    parser.add_argument(
        "--wsclean_tmpdir",
        type=str,
        default=os.environ["TMPDIR"] if "TMPDIR" in os.environ else "/tmp",
        help="Set the temporary directory of wsclean used when reordering files. CAUTION: This directory needs to be visible for LINC, in particular if you use Docker or Singularity.",
    )
    parser.add_argument(
        "--make_structure_plot",
        type=bool,
        default=True,
        help="Plot the structure function.",
    )
    parser.add_argument(
        "--selfcal_region",
        type=cwl_file,
        default=None,
        help="DS9-compatible region file to select the image regions used for the self-calibration.",
    )
    parser.add_argument(
        "--skymodel_fluxlimit",
        type=float,
        default=None,
        help="Limits the input skymodel to sources that exceed the given flux density limit in Jy (default: None for HBA, i.e. all sources of the catalogue will be kept, and 1.0 for LBA).",
    )


def add_arguments_vlbi_delay_calibrator(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--solset",
        type=cwl_file,
        help="The solution tables generated by the LINC target pipeline in an HDF5 format.",
    )
    parser.add_argument(
        "--delay_calibrator",
        type=cwl_file,
        help="A delay calibrator catalogue in CSV format.",
    )
    parser.add_argument(
        "--ddf_solset",
        type=cwl_file,
        default=None,
        help="The solution tables generated by the DDF pipeline, in HDF5 format.",
    )
    parser.add_argument(
        "--filter_baselines",
        type=str,
        default="*&",
        help="The default filter constraints for the dp3_prep_target step.",
    )
    parser.add_argument(
        "--flag_baselines",
        type=str,
        nargs="*",
        default=[],
        help="The pattern used by DP3 to flag baselines, e.g. [ CS013HBA*&&* ].",
    )
    parser.add_argument(
        "--phasesol",
        type=str,
        default="TGSSphase",
        help="The name of the target solution table to use from the solset input.",
    )
    parser.add_argument(
        "--configfile",
        type=cwl_file,
        help="Settings for the delay calibration in delay_solve.",
    )
    parser.add_argument(
        "--selfcal", type=cwl_dir, help="Path of external calibration scripts."
    )
    parser.add_argument(
        "--h5merger",
        type=cwl_dir,
        help="External LOFAR helper scripts for merging h5 files.",
    )
    parser.add_argument(
        "--linc", type=cwl_dir, help="The installation directory of LINC"
    )
    parser.add_argument(
        "--reference_stationSB",
        type=int,
        default=104,
        help="Subbands are concatenated in the concatenate-flag workflow relative to this station subband.",
    )
    parser.add_argument(
        "--number_cores",
        type=int,
        default=12,
        help="Number of cores to use per job for tasks with high I/O or memory.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=5,
        help="Number of threads per process for DP3.",
    )


def add_arguments_vlbi_split_directions(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--delay_solset", type=cwl_file, default="", help="Delay calibration solutions."
    )
    parser.add_argument(
        "--image_cat",
        type=cwl_file,
        default=cwl_file("lotss_catalogue.csv"),
        help="Catalogue containing target sources for imaging after delay calibration.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=10,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--numbands",
        type=int,
        default=-1,
        help="The number of bands to group. -1 means all bands.",
    )
    parser.add_argument(
        "--truncateLastSBs",
        type=bool,
        default=True,
        help="Whether to truncate the last subbands of the MSs to the same length.",
    )
    parser.add_argument(
        "--do_selfcal",
        type=bool,
        default=False,
        help="Self calibrate the split out targets.",
    )
    parser.add_argument(
        "--configfile",
        type=cwl_file,
        default="",
        help="Settings for the delay calibration in delay_solve.",
    )
    parser.add_argument(
        "--h5merger",
        type=cwl_dir,
        default="",
        help="Path to the lofar_helpers repository.",
    )
    parser.add_argument(
        "--selfcal",
        type=cwl_dir,
        default="",
        help="Path to facetselfcal repository.",
    )
    parser.add_argument(
        "--linc", type=cwl_dir, help="The installation directory of LINC"
    )


def add_arguments_vlbi_setup(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--solset",
        type=cwl_file,
        help="The solution tables generated by the LINC target pipeline in an HDF5 format.",
    )
    parser.add_argument(
        "--filter_baselines",
        type=str,
        default="*&",
        help="The default filter constraints for the dp3_prep_target step.",
    )
    parser.add_argument(
        "--flag_baselines",
        type=str,
        nargs="*",
        default=[],
        help="DP3-compatible pattern for baselines or stations to be flagged (may be an empty list.",
    )
    parser.add_argument(
        "--phasesol",
        type=str,
        default="TGSSphase",
        help="The name of the target solution table to use from the solset input.",
    )
    parser.add_argument(
        "--min_separation",
        type=int,
        default=30,
        help="",
    )
    parser.add_argument(
        "--number_cores",
        type=int,
        default=12,
        help="Number of cores to use per job for tasks with high I/O or memory.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=5,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--linc", type=cwl_dir, help="The installation directory of LINC"
    )


def add_arguments_vlbi_concatenate_flag(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--ddf_solset",
        type=cwl_file,
        default=None,
        help="The solution tables generated by the DDF pipeline, in HDF5 format.",
    )
    parser.add_argument(
        "--numbands",
        type=int,
        default=10,
        help="The number of bands to group. -1 means all bands.",
    )
    parser.add_argument(
        "--firstSB",
        type=int,
        default=None,
        help="If set, reference the grouping of files to this station subband.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=5,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--linc", type=cwl_dir, help="The installation directory of LINC"
    )
    parser.add_argument(
        "--aoflagger_memory_fraction",
        type=int,
        default=15,
        help="The fraction of the node's memory that will be used by AOFlagger (and should be available before an AOFlagger job can start).",
    )


def add_arguments_vlbi_phaseup_concat(parser):
    parser.add_argument(
        "--msin",
        type=cwl_dir,
        nargs="*",
        default=[],
        help="Raw input data in MeasurementSet format.",
    )
    parser.add_argument(
        "--delay_calibrator",
        type=cwl_file,
        help="A delay calibrator catalogue in CSV format.",
    )
    parser.add_argument(
        "--numbands",
        type=int,
        default=-1,
        help="The number of bands to group. -1 means all bands.",
    )
    parser.add_argument(
        "--firstSB",
        type=int,
        default=None,
        help="If set, reference the grouping of files to this station subband.",
    )
    parser.add_argument(
        "--configfile",
        type=cwl_file,
        help="Settings for the delay calibration in delay_solve.",
    )
    parser.add_argument(
        "--selfcal", type=cwl_dir, help="Path of external calibration scripts."
    )
    parser.add_argument(
        "--h5merger",
        type=cwl_dir,
        help="External LOFAR helper scripts for merging h5 files.",
    )
    parser.add_argument(
        "--flags",
        type=cwl_file,
        help="Flagging information in JSON format.",
    )
    parser.add_argument(
        "--pipeline",
        type=str,
        default="VLBI",
        help="Name of the pipeline.",
    )
    parser.add_argument(
        "--run_type",
        type=str,
        default="sol000",
        help="Type of the pipeline.",
    )
    parser.add_argument(
        "--filter_baselines",
        type=str,
        default="[CR]S*&",
        help="Selects only this set of baselines to be processed. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.",
    )
    parser.add_argument(
        "--bad_antennas",
        type=str,
        default="[CR]S*&",
        help="Antenna string to be processed.",
    )
    parser.add_argument(
        "--compare_stations_filter",
        type=str,
        default="[CR]S*&",
        help="",
    )
    parser.add_argument(
        "--check_Ateam_separation.json",
        type=cwl_file,
        help="",
    )
    parser.add_argument(
        "--clip_sources",
        type=str,
        nargs="*",
        default=[],
        help="",
    )
    parser.add_argument(
        "--removed_bands",
        type=str,
        nargs="*",
        default=[],
        help="The list of bands that were removed from the data.",
    )
    parser.add_argument(
        "--min_unflagged_fraction",
        type=float,
        default=0.5,
        help="The minimum fraction of unflagged data per band to continue.",
    )
    parser.add_argument(
        "--refant",
        type=str,
        default="CS001HBA0",
        help="The reference antenna used.",
    )
    parser.add_argument(
        "--max_dp3_threads",
        type=int,
        default=5,
        help="Number of threads per process for DP3.",
    )
    parser.add_argument(
        "--linc", type=cwl_dir, help="The installation directory of LINC"
    )


def cwl_file(entry: str) -> Union[str, None]:
    """Create a CWL-friendly file entry."""
    if entry is None:
        return None
    if entry.lower() == "null":
        return None
    else:
        return json.loads(f'{{"class": "File", "path":"{os.path.abspath(entry)}"}}')


def cwl_dir(entry: str) -> Union[str, None]:
    """Create a CWL-friendly directory entry."""
    if entry is None:
        return None
    if entry.lower() == "null":
        return None
    else:
        return json.loads(
            f'{{"class": "Directory", "path":"{os.path.abspath(entry)}"}}'
        )


if __name__ == "__main__":
    if "LINC_DATA_ROOT" not in os.environ:
        print(
            "WARNING: LINC_DATA_ROOT environment variable has not been set! Please set this variable and rerun the script."
        )
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="Generate an input file for LINC or VLBI-cwl in JSON format",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    subparsers = parser.add_subparsers(
        dest="parser", help="Pipeline to generate a configuration file for."
    )

    subparser_linc = subparsers.add_parser(
        "LINC", help="Generate a configuration file for LINC."
    )
    modeparser_linc = subparser_linc.add_subparsers(
        title="LINC",
        dest="parser_LINC",
        help="Workflow or sub-workflow to generate a configuration file for.",
    )
    modeparser_linc_calibrator = modeparser_linc.add_parser(
        "calibrator",
        help="Generate a configuration file for LINC Calibrator.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_linc_target = modeparser_linc.add_parser(
        "target",
        help="Generate a configuration file for LINC Target.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    subparser_vlbi = subparsers.add_parser(
        "VLBI",
        help="Generate a configuration file for VLBI-cwl.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_vlbi = subparser_vlbi.add_subparsers(
        title="VLBI",
        dest="parser_VLBI",
        help="Workflow or sub-workflow to generate a configuration file for.",
    )
    modeparser_vlbi_delay_calibration = modeparser_vlbi.add_parser(
        "delay_calibration",
        help="Generate a configuration file for the delay-calibration.cwl workflow.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_vlbi_split_directions = modeparser_vlbi.add_parser(
        "split_directions",
        help="Generate a configuration file for the split-directions.cwl workflow.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_vlbi_setup = modeparser_vlbi.add_parser(
        "setup",
        help="Generate a configuration file for the setup.cwl sub-workflow.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_vlbi_concatenate_flag = modeparser_vlbi.add_parser(
        "concatenate_flag",
        help="Generate a configuration file for the concatenate-flag.cwl sub-workflow.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modeparser_vlbi_phaseup_concat = modeparser_vlbi.add_parser(
        "phaseup_concat",
        help="Generate a configuration file for the phaseup-concat.cwl sub-workflow.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    add_arguments_linc_calibrator(modeparser_linc_calibrator)
    add_arguments_linc_target(modeparser_linc_target)

    add_arguments_vlbi_delay_calibrator(modeparser_vlbi_delay_calibration)
    add_arguments_vlbi_split_directions(modeparser_vlbi_split_directions)
    add_arguments_vlbi_setup(modeparser_vlbi_setup)
    add_arguments_vlbi_concatenate_flag(modeparser_vlbi_concatenate_flag)
    add_arguments_vlbi_phaseup_concat(modeparser_vlbi_phaseup_concat)

    args = vars(parser.parse_args())
