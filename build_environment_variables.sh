export FLOCS_VERSION="6.2.0"
export AOFLAGGER_VERSION=c8681861
export CASACORE_VERSION=5b671c5
export DDFPIPELINE_VERSION=df58808
export DP3_VERSION=e762f121
export EVERYBEAM_VERSION=f9315d33
export HDF5_VERSION=1.14.5
export IDG_VERSION=216e7443
export LOSOTO_VERSION=a7ab176
export OPENBLAS_VERSION=v0.3.31
export PYBDSF_VERSION=8b33037
export PYTHON_CASACORE_VERSION=3.6.1
export WSCLEAN_VERSION=2b1a430c

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

if [ "$NOAVX512" = "true" ]; then
    export FFLAGS="-march=${MARCH} -mtune=${MTUNE} -mno-avx512f"
    export CFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -mno-avx512f"
    export CXXFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -std=${CPPSTD} -mno-avx512f"
else
    export CFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe "
    export CXXFLAGS="-w -march=${MARCH} -mtune=${MTUNE} -pipe -std=${CPPSTD}"
    export FFLAGS="-march=${MARCH} -mtune=${MTUNE}"
fi
if [ "$DEBUG" = "true" ]; then
    export CFLAGS="-g $CFLAGS"
    export CXXFLAGS="-g $CXXFLAGS"
    export CMAKE_ADD_OPTION="-LA"
else
    export CMAKE_ADD_OPTION="-Wno-dev"
fi


CPLUS_INCLUDE_PATH_TAB=(
    $INSTALLDIR/casacore/include
    $INSTALLDIR/EveryBeam/include
    $INSTALLDIR/idg/include
    /opt/hdf5/include
    /opt/OpenBLAS/include
    /usr/include/c++/15
    /usr/include/cfitsio
    /usr/include/freetype2/freetype
    /usr/include/freetype2/freetype/config
    /usr/include/openmpi-x86_64
    /usr/include/python${PYTHON_VERSION}
    /usr/include/wcslib
    /usr/local/include/boost
)

CPATH_TAB=(
    ${INSTALLDIR}/casacore/include
    $INSTALLDIR/aoflagger/include
    $INSTALLDIR/EveryBeam/include
    $INSTALLDIR/idg/include
    /opt/hdf5/include
    /opt/OpenBLAS/include
    /usr/include/freetype2/freetype/config
    /usr/include/openmpi-x86_64
    /usr/include/python${PYTHON_VERSION}
    /usr/include/wcslib
    /usr/local/cuda/include
    /usr/local/include/boost
)

CMAKE_PREFIX_PATH_TAB=(
    $INSTALLDIR/aoflagger
    $INSTALLDIR/casacore
    $INSTALLDIR/EveryBeam
    $INSTALLDIR/idg
    $INSTALLDIR/lofar
    /opt/hdf5
    /opt/OpenBLAS
    /usr/lib64/openmpi
)

LD_LIBRARY_PATH_TAB=(
    $INSTALLDIR/aoflagger/lib
    $INSTALLDIR/casacore/lib
    $INSTALLDIR/EveryBeam/lib
    $INSTALLDIR/idg/lib
    $INSTALLDIR/lofarstman/lib64
    $INSTALLDIR/sagecal/lib
    /opt/hdf5/lib
    /opt/OpenBLAS/lib64
    /usr/lib64/openmpi/lib
    /usr/local/lib
    ${LD_LIBRARY_PATH}
)

PATH_TAB=(
    /opt/hdf5/bin
    /usr/lib64/openmpi/bin
    ${PATH}
)

export \
   CPLUS_INCLUDE_PATH=$(IFS=:; echo "${CPLUS_INCLUDE_PATH_TAB[*]}") \
   CPATH=$(IFS=:; echo "${CPATH_TAB[*]}") \
   CMAKE_PREFIX_PATH=$(IFS=:; echo "${CMAKE_PREFIX_PATH_TAB[*]}") \
   LD_LIBRARY_PATH=$(IFS=:; echo "${LD_LIBRARY_PATH_TAB[*]}") \
   PATH=$(IFS=:; echo "${PATH_TAB[*]}")


export CFLAGS="$CFLAGS -Wno-error=incompatible-pointer-types"
export CXXFLAGS="$CXXFLAGS -Wno-error=incompatible-pointer-types"
