export FLOCS_VERSION="6.2.0"
export AOFLAGGER_VERSION=1ffcb9c8
export CASACORE_VERSION=aaf72eb
export DDFPIPELINE_VERSION=df58808
export DP3_VERSION=f89c81f4
export EVERYBEAM_VERSION=f72a0fb1
export HDF5_VERSION=1.14.5
export IDG_VERSION=faf26bc0
export LOSOTO_VERSION=2.7.1
export OPENBLAS_VERSION=v0.3.31
export PYBDSF_VERSION=8b33037
export PYTHON_CASACORE_VERSION=3.6.1
export WSCLEAN_VERSION=e8711ef0

# Expert settings below. Generally these won't have to be touched.
# General environment settings.
export J=$(nproc)
export INSTALLDIR=/opt/lofar
export PYTHON_VERSION=3.12
export HDF5_USE_FILE_LOCKING=FALSE
export OMPI_ALLOW_RUN_AS_ROOT=1

# Build settings
export CPPSTD=c++17
export OMP_NUM_THREADS=1
export OMP_MAX_THREADS=1
export OPENBLAS_NUM_THREADS=1
export BLIS_NUM_THREADS=$OPENBLAS_NUM_THREADS
export NUM_THREADS=256

# MARCH and MTUNE are set apptainer arguments. These are assumed to be defined when this script is sourced.
if [ "$NOAVX512" = "true" ]; then
    export FFLAGS="-march=${MARCH} -mtune=${MTUNE} -mno-avx512f"
    export CFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -mno-avx512f"
    export CXXFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -std=${CPPSTD} -mno-avx512f"
else
    export CFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe"
    export CXXFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -std=${CPPSTD}"
    export FFLAGS="-march=${MARCH} -mtune=${MTUNE}"
fi

# CMAKE_ADD_OPTION is a custom variable of flags that are added at build time when cmake is invoked.
if [ "$DEBUG" = "true" ]; then
    export CFLAGS="-g $CFLAGS"
    export CXXFLAGS="-g $CXXFLAGS"
    export FFLAGS="-g $FFLAGS"
    export CMAKE_ADD_OPTION="-LA"
else
    export CMAKE_ADD_OPTION="-Wno-dev"
fi
export CPLUS_INCLUDE_PATH="/usr/local/include/boost:/opt/hdf5/include:/opt/OpenBLAS/include:/usr/include/openmpi-x86_64:/usr/include/c++/15:/usr/include/python${PYTHON_VERSION}:$INSTALLDIR/casacore/include:/usr/include/cfitsio:$INSTALLDIR/idg/include:$INSTALLDIR/EveryBeam/include:/usr/include/wcslib:/usr/include/freetype2/freetype:/usr/include/freetype2/freetype/config"
export CPATH="/usr/local/include/boost:/usr/include/python${PYTHON_VERSION}:/opt/hdf5/include:/opt/OpenBLAS/include:/usr/include/openmpi-x86_64:/usr/local/cuda/include:${INSTALLDIR}/casacore/include:$INSTALLDIR/idg/include:$INSTALLDIR/aoflagger/include:$INSTALLDIR/EveryBeam/include:/usr/include/wcslib:/usr/include/freetype2/freetype/config"
export CMAKE_PREFIX_PATH="/opt/hdf5:/opt/OpenBLAS:$INSTALLDIR/aoflagger:$INSTALLDIR/casacore:$INSTALLDIR/lofar:$INSTALLDIR/idg:/usr/lib64/openmpi:$INSTALLDIR/EveryBeam"
export LD_LIBRARY_PATH="/usr/local/lib:/opt/hdf5/lib:$INSTALLDIR/lofarstman/lib64:/opt/OpenBLAS/lib64:$INSTALLDIR/aoflagger/lib:$INSTALLDIR/casacore/lib:$INSTALLDIR/idg/lib:/usr/lib64/openmpi/lib:$INSTALLDIR/EveryBeam/lib:$INSTALLDIR/sagecal/lib:$LD_LIBRARY_PATH"
export PATH="/opt/hdf5/bin:/usr/lib64/openmpi/bin:$PATH"

export CFLAGS="$CFLAGS -Wno-error=incompatible-pointer-types"
export CXXFLAGS="$CXXFLAGS -Wno-error=incompatible-pointer-types"

