export CC=`which mpicc`
export CXX=`which mpic++`
mkdir /opt/hdf5
cd /opt/hdf5
export HDF5_VERSION_USCORE=${HDF5_VERSION//./_}
wget --progress=bar:force:noscroll https://support.hdfgroup.org/releases/hdf5/v${HDF5_VERSION_USCORE%_*}/v${HDF5_VERSION_USCORE}/downloads/hdf5-${HDF5_VERSION}.tar.gz
gunzip hdf5-${HDF5_VERSION}.tar.gz
tar xf hdf5-${HDF5_VERSION}.tar
cd hdf5-${HDF5_VERSION}/
# Thread safety required for WSClean's parallel gridding with facets.
./configure -prefix=/opt/hdf5 --enable-build-mode=production --enable-threadsafe --enable-shared --disable-sharedlib-rpath --disable-hl --enable-cxx -enable-unsupported
make -j $J
#make check
make install
cd /opt/hdf5
rm -r hdf5-1.*
export CC=`which gcc`
export CXX=`which g++`
export HDF5_DIR=/opt/hdf5
