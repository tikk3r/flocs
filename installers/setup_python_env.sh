sudo dnf -y install python3-cx-oracle python3.12 python3.12-devel
pip install uv
export PATH="/root/.local/bin:$PATH"

uv tool install shadems --with "pyarrow,dask<2025"
uv tool install lofar-vlbi-plot --with "python-casacore"
uv tool install breizorro

# Install the normal Python environment.
uv venv --seed --python=python3.12 $INSTALLDIR/pyenv-py3
# Without this the environment doesn't load.
sed -i "29,41d" $INSTALLDIR/pyenv-py3/bin/activate
source $INSTALLDIR/pyenv-py3/bin/activate

git clone https://github.com/mattyowl/astLib.git
export CC=`which gcc-14`
patch astLib/setup.py flocs/patches/astlib.patch
uv pip install --upgrade pip wheel Cython "setuptools>=59.5.0,<71"
uv pip install ./astLib
rm -rf ./astLib
export CC=`which gcc`
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
uv pip install --no-build-isolation git+https://github.com/sara-nl/cortExchange#egg=cortexchange
uv pip install scikit_build_core setuptools_scm
uv pip install "numpy<2.5"
uv pip install --no-binary pandas pandas
uv pip install --no-binary h5py h5py
cat $INSTALLDIR/flocs/requirements.txt | xargs -n 1 uv pip install --no-build-isolation
# Install facetselfcal this way to make sure data gets installed.
cd /opt/lofar
git clone https://github.com/rvweeren/lofar_facet_selfcal.git
cd lofar_facet_selfcal
cd ..
uv pip install ./lofar_facet_selfcal
# Install this separately since it keeps forcefully downgrading numpy.
#pip install --no-deps lofarSun
uv pip install $INSTALLDIR/flocs
