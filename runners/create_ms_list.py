import argparse
import glob
import json
import os
import sys

from losoto.h5parm import h5parm

import casacore.tables as ct
import numpy as np

def cwl_file(entry: str) -> str:
    """ Create a CWL-friendly file entry."""
    if entry.lower() == 'null':
        return None
    else:
        return json.loads(f'{{"class": "File", "path":"{entry}"}}')

def cwl_dir(entry: str) -> str:
    """ Create a CWL-friendly directory entry."""
    if entry.lower() == 'null':
        return None
    else:
        return json.loads(f'{{"class": "Directory", "path":"{entry}"}}')

def check_dd_freq(infile: str, freq_array: np.ndarray) -> bool:
    """ Check frequency coverage overlap between a Measurment Set and a given array of frequencies.
    
    Args:
        infile: input Measurement Set to check
        freq_array: array of frequencies to check against
    Returns:
        True if input frequencies are covered, False if input has frequencies that fall outside freq_array.
    """
    msfreqs = ct.table(('{:s}::SPECTRAL_WINDOW').format(infile))
    ref_freq = msfreqs.getcol('REF_FREQUENCY')[0]
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

def get_dico_freqs(input_dir: str, solnames: str = 'killMS.DIS2_full.sols.npz') -> list:
    """ Extract frequencies from killMS format solutions.
    
    Args:
        input_dir: directory where the solutions are stored, usually called SOLSDIR.
        solnames: name of the solution files.
    Returns:
        freqs: array of frequencies covered by the solutions.
    """
    sol_dirs = glob.glob(os.path.join(input_dir, 'L*pre-cal.ms'))
    freqs = []
    for sol_dir in sol_dirs:
        npz_file = os.path.join(sol_dir, solnames)
        SolDico = np.load(npz_file)
        fmin = np.min(SolDico['FreqDomains'])
        fmax = np.max(SolDico['FreqDomains'])
        tmp_freqs = np.array([fmin, fmax])
        freqs.append(tmp_freqs)
        SolDico.close()

    return freqs

def get_prefactor_freqs(solname: str = 'solutions.h5', solset: str = 'target') -> list:
    """ Extract frequency coverage from LINC solutions.
    
    Args:
        solname: name of the LINC solution file.
        solset: name of the solset to use.
    Returns:
        f_arr: array of frequencies covered by the solutions.
    """
    sols = h5parm(solname)
    ss = sols.getSolset(solset)
    st_names = ss.getSoltabNames()
    ph_sol_name = [xx for xx in st_names if 'extract' not in xx][0]
    st = ss.getSoltab(ph_sol_name)
    freqs = st.getAxisValues('freq')
    freqstep = 1953125.0  ## the value for 10 subbands
    f_arr = []
    for xx in range(len(freqs)):
        fmin = freqs[xx] - freqstep/2.
        fmax = freqs[xx] + freqstep/2.
        f_arr.append(np.array([fmin,fmax]))
    return f_arr

def get_reffreq(msfile: str) -> float:
    """ Get the reference frequency of a Measurement Set.
    
    Args:
        msfile: input Measurement Set.
    """
    ss = ("taql 'select REF_FREQUENCY from {:s}::SPECTRAL_WINDOW' > tmp.txt").format(msfile)
    os.system(ss)
    with open('tmp.txt', 'r') as (f):
        lines = f.readlines()
    f.close()
    os.system('rm tmp.txt')
    freq = np.float64(lines[(-1)])
    return freq

class LINCJSONConfig:
    """ Class for generating JSON configuration files to be passed to the LINC pipeline."""
    def __init__(self, mspath: str):
        self.configdict = {}
        
        print('Searching ' + os.path.abspath(mspath).rstrip('/') + '/*.MS')
        files = sorted(glob.glob(os.path.abspath(mspath).rstrip('/') + '/*.MS'))
        print(f'Found {len(files)} files')

        mslist = []
        for ms in files:
            x = json.loads(f'{{"class": "Directory", "path":"{ms}"}}')
            mslist.append(x)

        self.configdict['msin'] = mslist

    def add_entry(self, key: str, value: object):
        if 'ATeam' in key:
            self.configdict['A-Team_skymodel'] = value
        else:
            self.configdict[key] = value

    def save(self, fname: str):
        if not fname.endswith('.json'):
            fname += '.json'
        with open(fname, 'w') as outfile:
            json.dump(self.configdict, outfile, indent=4)

class VLBIJSONConfig(LINCJSONConfig):
    """ Class for generating JSON configuration files to be passed to the lofar-vlbi pipeline."""
    def __init__(self, mspath: str, prefac_h5parm: str, ddf_solsdir: str):
        self.configdict = {}
        
        print('Searching ' + os.path.abspath(mspath).rstrip('/') + '/*.MS')
        files = sorted(glob.glob(os.path.abspath(mspath).rstrip('/') + '/*.MS'))
        print(f'Found {len(files)} files')

        prefac_freqs = get_prefactor_freqs(solname = prefac_h5parm['path'], solset = 'target')

        mslist = []
        for dd in files:
            if check_dd_freq(dd, prefac_freqs ):
                mslist.append(dd)
        if os.path.exists(ddf_solsdir['path']):
            ddf_freqs = get_dico_freqs(ddf_solsdir['path'], solnames='killMS.DIS2_full.sols.npz' )
            tmplist = []
            for dd in mslist:
                if check_dd_freq(dd, ddf_freqs ):
                    tmplist.append(dd)
            mslist = tmplist
        
        final_mslist = []
        for ms in mslist:
            x = json.loads(f'{{"class": "Directory", "path":"{ms}"}}')
            final_mslist.append(x)
        self.configdict['msin'] = final_mslist
        
if __name__ == '__main__':
    if 'LINC_DATA_ROOT' not in os.environ:
        print('WARNING: LINC_DATA_ROOT environment variable has not been set! Please set this variable and rerun the script.')
        sys.exit(1)

    parser = argparse.ArgumentParser(description='Generate an input file for LINC containing measurement sets and, optionally, the calibrator solutions.')
    parser.add_argument('mspath', type=str, help='Path where input measurement sets are located.')

    vlbiparser = parser.add_argument_group('== lofar-vlbi specific settings ==')
    vlbiparser.add_argument('--vlbi', action='store_true', default=False, help='Triggers alternate mode to generate a config file for the lofar-vlbi pipeline.')
    vlbiparser.add_argument('--solset', type=cwl_file, default='', help='Path to the final LINC target solution file (usually cal_solutions.h5).')
    vlbiparser.add_argument('--ddf_solsdir', type=cwl_file, default='', help='Path to where ddf-pipeline solutions can be found (usually SOLSDIR).')
    vlbiparser.add_argument('--delay_calibrator', type=cwl_file, default='', help='A delay calibrator catalogue in CSV format.')
    vlbiparser.add_argument('--ddf_solset', type=cwl_file, default='', help='The solution tables generated by the DDF pipeline in an HDF5 format.')
    vlbiparser.add_argument('--configfile', type=cwl_file, default='', help='Settings for the delay calibration in delay_solve.')
    vlbiparser.add_argument('--h5merger', type=cwl_dir, default='', help='Path to the lofar_helpers repository.')
    vlbiparser.add_argument('--facetselfcal', type=cwl_dir, default='', help='Path to facetselfcal repository.')
    vlbiparser.add_argument('--phasesol', type=str, default='TGSSphase', help='Name of the soltab with LINC target phase solutions.')
    vlbiparser.add_argument('--reference_stationSB', type=int, default=104, help='Name of the soltab with LINC target phase solutions.')
    vlbiparser.add_argument('--number_cores', type=int, default=12, help='Number of cores to use per job for tasks with high I/O or memory.')

    dparser = parser.add_argument_group('== Data and calibration ==')
    dparser.add_argument('--cal_solutions', type=cwl_file, default='', help='Path to the final LINC calibrator solution file.')
    dparser.add_argument('--avg_timeresolution', type=float, default=4, help='Intermediate time resolution of the data in seconds after averaging.')
    dparser.add_argument('--avg_timeresolution_concat', type=float, default=8, help='Final time resolution of the data in seconds after averaging and concatenation.')
    dparser.add_argument('--avg_freqresolution', type=str, default='48.82kHz', help='Intermediate frequency resolution of the data after averaging.')
    dparser.add_argument('--avg_freqresolution_concat', type=str, default='97.64kHz', help='Final frequency resolution of the data after averaging and concatenation.')
    dparser.add_argument('--bandpass_freqresolution', type=str, default='195.3125kHz', help='Frequency resolution of the bandpass solution table.')
    dparser.add_argument('--refant', type=str, default='CS00.*', help='Regular expression of the stations that are allowed to be selected as a reference antenna by the pipeline.')
    dparser.add_argument('--flag_baselines', type=str, nargs='*', default=[], help='DP3-compatible pattern for baselines or stations to be flagged (may be an empty list.')
    dparser.add_argument('--process_baselines_cal', type=str, default='*&', help='Performs A-Team-clipping/demixing and direction-independent phase-only self-calibration only on these baselines. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.')
    dparser.add_argument('--process_baselines_target', type=str, default='*&', help='Performs A-Team-clipping/demixing and direction-independent phase-only self-calibration only on these baselines. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.')
    dparser.add_argument('--filter_baselines', type=str, default='*&', help='Selects only this set of baselines to be processed. Choose [CR]S*& if you want to process only cross-correlations and remove international stations.')
    dparser.add_argument('--do_smooth', type=bool, default=False, help='Enable or disable baseline-based smoothing.')
    dparser.add_argument('--rfi_strategy', type=str, default=os.path.join(os.environ['LINC_DATA_ROOT'], 'rfistrategies', 'lofar-default.lua'), help='Path to the RFI flagging strategy to use with AOFlagger.')
    dparser.add_argument('--max2interpolate', type=int, default=30, help='Amount of channels in which interpolation should be performed for deriving the bandpass.')
    dparser.add_argument('--fit_offset_PA', type=bool, default=False, help='Assume that together with a delay each station has also a differential phase offset (important for old LBA observations).')
    dparser.add_argument('--interp_windowsize', type=int, default=15, help='Size of the window over which a value is interpolated. Should be odd.')
    dparser.add_argument('--ampRange', type=float, nargs='*', default=[0,0], help='Range of median amplitudes accepted per station.')
    dparser.add_argument('--skip_international', type=bool, default=True, help='Skip fitting the bandpass for international stations (this avoids flagging them in many cases).')
    dparser.add_argument('--raw_data', type=bool, default=False, help='Use autoweight. Set to True in case you are using raw data.')
    dparser.add_argument('--propagatesolutions', type=bool, default=True, help='Use already derived solutions as initial guess for the upcoming time slot.')
    dparser.add_argument('--flagunconverged', type=bool, default=False, help='Flag solutions for solves that did not converge (if they were also detected to diverge).')
    dparser.add_argument('--masStddev', type=float, default=-1.0, help='Maximum allowable standard deviation when outlier clipping is done. For phases, this should value should be in radians, for amplitudes in log(amp). If None (or negative), a value of 0.1 rad is used for phases and 0.01 for amplitudes.')
    dparser.add_argument('--solutions2transfer', type=cwl_file, default='null', help='Provide own solutions from a reference calibrator observation in case calibrator source is not trusted.')
    dparser.add_argument('--antennas2transfer', type=str, default='[FUSPID].*', help='DP3-compatible baseline pattern for those stations who should get calibration solutions from a reference solution set in case calibrator source is not trusted.')
    dparser.add_argument('--do_transfer', type=bool, default=False, help='Enable solutions transfer for non-trusted calibrator sources.')
    dparser.add_argument('--trusted_sources', type=str, default='3C48,3C147,3C196,3C295,3C380', help='Comma-separated list of trusted calibrator sources. Solutions are only transferred from a reference solution set in case the observed calibrator is not among them.')
    dparser.add_argument('--ion_3rd', type=bool, default=False, help='Take into account also 3rd-order effects for the clock-TEC separation.')
    dparser.add_argument('--clock_smooth', type=bool, default=True, help='Only take the median of the derived clock solutions (enable this in case of non-joint observations).')
    dparser.add_argument('--compression_bitrate', type=int, default=0, help='Minimal fraction of unflagged data to be accepted for further processing of the data chunk.')

    dparser.add_argument('--apply_tec', type=bool, default=False, help='Apply TEC solutions from the calibrator (default: False).')
    dparser.add_argument('--apply_clock', type=bool, default=True, help='Apply clock solutions from the calibrator (default: True).')
    dparser.add_argument('--apply_phase', type=bool, default=False, help='Apply full phase solutions from the calibrator (default: False).')
    dparser.add_argument('--apply_RM', type=bool, default=True, help='Apply ionospheric Rotation Measure from RMextract (default: True).')
    dparser.add_argument('--apply_beam', type=bool, default=True, help='Apply element beam corrections (default: True).')
    dparser.add_argument('--gsmcal_step', type=str, default='phase', help='Type of calibration to be performed in the self-calibration step (default: phase)')
    dparser.add_argument('--selfcal', type=bool, default=False, help='Perform extensive self-calibration according to the LiLF scheme (recommended for LBA observations) (default: false)')

    demixparser = parser.add_argument_group('== Demixing ==')
    demixparser.add_argument('--demix_sources', type=str, nargs='*', default=['CasA', 'CygA'], help='Sources to demix.')
    demixparser.add_argument('--demix_freqres', type=str, default='48.82kHz', help='Frequency resolution used when demixing.')
    demixparser.add_argument('--demix_timeres', type=float, default=10, help='Frequency resolution used when demixing.')
    demixparser.add_argument('--demix', type=str, default=None, help='If true force demixing using all sources of demix_sources, if false do not demix (default: null, automatically determines sources to be demixed according to min_separation).')
    demixparser.add_argument('--lbfgs_historysize', type=int, default=10, help='For the LBFGS solver: the history size, specified as a multiple of the parameter vector, to use to approximate the inverse Hessian.')
    demixparser.add_argument('--lbfgs_robustdof', type=int, default=200, help='For the LBFGS solver: the degrees of freedom (DOF) given to the noise model.')

    perfparser = parser.add_argument_group('== Performance ==')
    perfparser.add_argument('--max_dp3_threads', type=int, default=10, help='Number of threads per process for DP3.')
    perfparser.add_argument('--memoryperc', type=int, default=20, help='Maximum of memory used for aoflagger in raw_flagging mode in percent.')
    perfparser.add_argument('--aoflag_reorder', type=bool, default=False, help='Make aoflagger reorder the measurement set before running the detection. This prevents that aoflagger will use its memory reading mode, which is faster but uses more memory.')
    perfparser.add_argument('--aoflag_chunksize', type=int, default=2000, help='Split the set into intervals with the given maximum size, and flag each interval independently. This lowers the amount of memory required.')
    perfparser.add_argument('--aoflag_freqconcat', type=bool, default=True, help='Concatenate all subbands on-the-fly before performing flagging. Disable if you use time-chunked input data.')
    perfparser.add_argument('--wsclean_tmpdir', type=str, default=os.environ['TMPDIR'] if 'TMPDIR' in os.environ else '/tmp', help='Set the temporary directory of wsclean used when reordering files. CAUTION: This directory needs to be visible for LINC, in particular if you use Docker or Singularity.')

    skyparser = parser.add_argument_group('== Skymodel ==')
    skyparser.add_argument('--calibrator_path_skymodel', type=cwl_dir, default=os.path.join(os.environ['LINC_DATA_ROOT'], 'skymodels'), help='Directory where calibrator skymodels are located.')
    skyparser.add_argument('--max_separation_arcmin', type=float, default=1.0, help='Maximum separation between phase center of the observation and the patch of a calibrator skymodel which is accepted to be chosen as a skymodel.')
    skyparser.add_argument('--ATeam_skymodel', type=cwl_file, default=None, help='File path to the A-Team skymodel.')

    args = vars(parser.parse_args())

    if args['vlbi']:
        print('Generating LOFAR-VLBI config')
        config = VLBIJSONConfig(args['mspath'], prefac_h5parm=args['solset'], ddf_solsdir=args['ddf_solsdir'])
        # Input MS are a special case and no longer needed after this.
        args.pop('mspath')
        args.pop('vlbi')
        # Temporary workaround until CWL workflows align.
        args['flag_baselines'] = str(args['flag_baselines'])
        # For LINC selfcal is a boolean, so until this clash is resolved overwrite it on the fly.
        args['selfcal'] = args.pop('facetselfcal')
        for key, val in args.items():
            config.add_entry(key, val)
        config.save('mslist.json')
    else:
        print('Generating LINC config')
        config = LINCJSONConfig(args['mspath'])
        # Input MS are a special case and no longer needed after this.
        args.pop('mspath')
        args.pop('vlbi')
        for key, val in args.items():
            config.add_entry(key, val)
        config.save('mslist.json')