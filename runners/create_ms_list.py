import glob
import os
import sys

print('Searching ' + os.path.abspath(sys.argv[1]).rstrip('/') + '/*.MS')
files = sorted(glob.glob(os.path.abspath(sys.argv[1]).rstrip('/') + '/*.MS'))
#files = glob.glob(os.path.abspath(sys.argv[1]).rstrip('/') + '/*.MS')
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
    out.write('}\n')
print('Input JSON written to mslist.json')
