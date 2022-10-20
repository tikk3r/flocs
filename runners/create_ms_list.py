import argparse
import glob
import os
import sys

def make_input_json(mspath, calsols=''):
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
    if calsols:
            calsolpath = os.path.abspath(calsols)
            out.write(f' "cal_solutions": {{"class": "File", "path":"{calsolpath}"}}\n')
    out.write('}\n')
    print('Input JSON written to mslist.json')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate an input file for LINC containing measurement sets and, optionally, the calibrator solutions.')
    parser.add_argument('mspath', type=str, help='Path where input measurement sets are located.')
    parser.add_argument('--calsols', type=str, default='', help='Path to the final LINC calibrator solution file (usually cal_solutions.h5).')

    args = parser.parse_args()

    make_input_json(args['mspath'], args['calsols'])
