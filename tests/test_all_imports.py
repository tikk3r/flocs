import importlib
def try_import(module):
    try:
        importlib.import_module(module)
        return True
    except ModuleNotFoundError:
        return False

# System modules required by e.g. the facetselfcal script.
modules_system = ['argparse', 'ast', 'fnmatch', 'glob', 'itertools', 'multiprocessing', 'os', 'pickle', 're', 'subprocess', 'sys', 'time']
# Third party modules required by e.g. the facetselfcal script.
modules_thirdp = ['astropy', 'astroquery', 'bdsf', 'casacore.tables', 'lofar.stationresponse', 'losoto', 'matplotlib', 'numpy', 'pyregion', 'tables']

print('== Attempting import of required system modules')
for m in modules_system:
    print(f'Import of {m} ', end='')
    print('succeeded.' if try_import(m) else 'failed.')

print('== Attempting import of required third party modules')
for m in modules_thirdp:
    print(f'Import of {m} ', end='')
    print('succeeded.' if try_import(m) else 'failed.')
