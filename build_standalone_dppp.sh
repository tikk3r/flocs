export LIBDIR=/net/lofar1/data1/sweijen/software/LOFAR/2018_09_11 # Was installed with GCC 5.4.0, but seems to work.
export INSTALLDIR=/net/lofar1/data1/sweijen/software/test_dp3_sept

PATH_AOFLAGGER=/net/lofar1/data1/sweijen/software/LOFAR/2018_10_10/aoflagger
PATH_ARMADILLO=$LIBDIR/armadillo
PATH_BOOST=$LIBDIR/boost
PATH_CASACORE=$LIBDIR/casacore
PATH_CFITSIO=$LIBDIR/cfitsio
PATH_DYSCO=$LIBDIR/dysco
PATH_BLAS=$LIBDIR/openblas
PATH_LOFAR=$LIBDIR/lofar
PATH_SUPERLU=$LIBDIR/superlu
PATH_WCSLIB=$LIBDIR/wcslib

# Leiden specific.
module load cmake/3.9
module load make/4.2
module load gcc/8.1.0

export CC=`which gcc`
export CXX=`which g++`

mkdir -p $INSTALLDIR/dppp
cd $INSTALLDIR/dppp && git clone https://github.com/lofar-astron/DP3.git src
mkdir build && cd build
export CMAKE_PREFIX_PATH=$PATH_AOFLAGGER:$PATH_ARMADILLO:$PATH_BOOST:$PATH_CASACORE:$PATH_CFITSIO:$PATH_DYSCO:$PATH_BLAS:$PATH_SUPERLU:$PATH_WCSLIB:$PATH_LOFAR
export LD_LIBRARY_PATH=$PATH_LOFAR/lib64/:$PATH_SUPERLU/lib64:$LD_LIBRARY_PATH
cmake -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/dppp ../src && make -j12 && make install
