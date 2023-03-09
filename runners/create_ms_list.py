import argparse
import glob
import os
import sys 

def make_input_json(mspath, calsols='', targetsols='', path_facetselfcal_config='', path_lofar_helpers='', path_selfcal=''):
    ''' Creates the basic input JSON file for the LINC calibrator and target workflows.

    Args:
        mspath (str): path where the input MS are stored.
        calsols (str): path where cal_solutions.h5 from the calibrator run is stored.
    Returns:
        None
    '''
    print('Searching ' + os.path.abspath(mspath).rstrip('/') + '/*.MS')
    files = sorted(glob.glob(os.path.abspath(mspath).rstrip('/') + '/*.MS'))
    print(f'Found {len(files)} files')

    with open('mslist.json', 'w') as out:
        out.write('{\n')
        out.write('  "msin": [\n')
        for ms in files[:-1]:
            out.write(f'   {{"class": "Directory", "path":"{ms}"}},\n')
        else:
            ms = files[-1]
            out.write(f'   {{"class": "Directory", "path":"{ms}"}}\n')
        out.write('  ],\n')
        if calsols and targetsols:
            calsolpath = os.path.abspath(calsols)
            out.write(f' "cal_solutions": {{"class": "File", "path":"{calsolpath}"}},\n')
        else:
            calsolpath = os.path.abspath(calsols)
            out.write(f' "cal_solutions": {{"class": "File", "path":"{calsolpath}"}}\n')
        if targetsols and not calsols:
            print('Only target solutions given, preparing JSON file for lofar-vlbi pipeline.')
            calsolpath = os.path.abspath(targetsols)
            out.write(f' "solset": {{"class": "File", "path":"{calsolpath}"}}\n')
            out.write(f' "configfile": {{"class": "File", "path":"{path_facetselfcal_config}"}}\n')
            out.write(f' "h5merger": {{"class": "Directory", "path":"{path_lofar_helpers}"}}\n')
            out.write(f' "selfcal": {{"class": "DIrectory", "path":"{path_selfcal}"}}\n')

            
        out.write('}\n')
    print('Input JSON written to mslist.json')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate an input file for LINC containing measurement sets and, optionally, the calibrator solutions.')
    parser.add_argument('mspath', type=str, help='Path where input measurement sets are located.')
    parser.add_argument('--calsols', type=str, default='', help='Path to the final LINC calibrator solution file (usually cal_solutions.h5).')
    parser.add_argument('--targetsols', type=str, default='', help='Path to the final LINC target solution file (usually cal_solutions.h5).')
    parser.add_argument('--path_facetselfcal_config', type=str, default='', help='Path to the config file for facetselfcal.py.')
    parser.add_argument('--path_lofar_helpers', type=str, default='', help='Path to the lofar_helpers repository.')
    parser.add_argument('--path_selfcal', type=str, default='', help='Path to facetselfcal?')

    args = vars(parser.parse_args())

    make_input_json(args['mspath'], args['calsols'], args['targetsols'], args['path_facetselfcal_config'], args['path_lofar_helpers'], args['path_selfcal'])