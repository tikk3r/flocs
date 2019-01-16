# General environment settings.
export J=60
export INSTALLDIR=/path/to/installation/directory
export PYTHON_VERSION=2.7
export PYTHON_VERSION_NODOT=27
# Source additional stuff here if you want.

# General compile and build settings.
# Tweak your build environment here.
export make=`which cmake`
export cmake=`which cmake`
export CC=`which gcc`
export CXX=`which g++`
export CFLAGS="-D_GLIB_USE_CXX_ABI=1 -DBOOST_NO_CXX11_SCOPED_ENUMS"
export CXXFLAGS="-D_GLIB_USE_CXX_ABI=1 -DBOOST_NO_CXX11_SCOPED_ENUMS"

# Crash on a crash (doesn't seem veeery reliable).
set -e


# Settings relevant to the installed software.
export AOFLAGGER_VERSION=latest
# Do not change Armadillo version.
export ARMADILLO_VERSION=8.600.0
export BLAS_VERSION=0.2.17
export BOOST_DOT_VERSION=1.58.0
export BOOST_VERSION=1_58_0
export CASACORE_VERSION=v2.4.1
# Leave at latest.
export CASAREST_VERSION=latest
export CFITSIO_VERSION=3410
export DYSCO_VERSION=v1.0.1
export HDF5_VERSION=1.10.4
export LAPACK_VERSION=3.6.0
export LOFAR_VERSION=3_2_4
export LOSOTO_VERSION=2.0
export OPENBLAS_VERSION=v0.3.2
export PYBDSF_VERSION=v1.8.12
export PYTHON_CASACORE_VERSION=latest
# Do not change, Armadillo wants this version of SuperLU.
export SUPERLU_VERSION=v5.2.1
export WSCLEAN_VERSION=latest
export WCSLIB_VERSION=5.20

mkdir -p $INSTALLDIR

cd $INSTALLDIR && git clone git@github.com:tikk3r/lofar-grid-hpccloud.git
# Path to where the patch for python-casacore's setup is stored.
export PYTHON_CASACORE_PATCH=$INSTALLDIR/lofar-grid-hpccloud/patches/patch_python-casacore.patch
export PATCH_LOFAR=$INSTALLDIR/lofar-grid-hpccloud/patches/lofar.patch

##################################################
# The lines below should not need to be modified #
##################################################

#######################################
# Build all external libraries first. #
#######################################
#
# Install HDF5
#
: '
mkdir -p ${INSTALLDIR}/hdf5
cd ${INSTALLDIR}/hdf5 && wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz
cd ${INSTALLDIR}/hdf5 && tar xf hdf5*.tar.gz
cd ${INSTALLDIR}/hdf5/hdf5*/ && ./configure --prefix=${INSTALLDIR}/hdf5 --enable-fortran --enable-cxx
cd ${INSTALLDIR}/hdf5/hdf5*/ && $make -j ${J}
cd ${INSTALLDIR}/hdf5/hdf5*/ && $make install
'

if [ ! -d $INSTALLDIR/boost ]; then
    #
    # Install Boost.Python
    #
    echo Installing Boost.Python...
    mkdir -p $INSTALLDIR/boost/src
    cd $INSTALLDIR && wget http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.gz
    #cd $INSTALLDIR && tar xzf boost_${BOOST_VERSION}.tar.gz -C boost && cd boost/boost_${BOOST_VERSION} && ./bootstrap.sh --prefix=$INSTALLDIR/boost && ./b2 headers && ./b2 install --prefix=$INSTALLDIR/boost --with=all -j $J
    #cd $INSTALLDIR && tar xzf boost_${BOOST_VERSION}.tar.gz -C boost && cd boost/boost_${BOOST_VERSION} && ./bootstrap.sh --prefix=$INSTALLDIR/boost && ./b2 headers && ./b2 install --prefix=$INSTALLDIR/boost --with=all -j $J -define=_GLIBCXX_USE_CXX11_ABI=1
    cd $INSTALLDIR && tar xzf boost_1_58_0.tar.gz -C boost && cd boost/boost_1_58_0 && ./bootstrap.sh --prefix=$INSTALLDIR/boost && ./b2 headers && ./b2 install toolset=gcc cxxflags=-std=c++11 --prefix=$INSTALLDIR/boost --with-atomic --with-chrono --with-date_time --with-filesystem --with-program_options --with-python --with-signals --with-test --with-thread -j $J -define=_GLIBCXX_USE_CXX11_ABI=1
    #cd $INSTALLDIR && tar xzf boost_*.tar.gz -C boost && cd boost/boost_${BOOST_VERSION} && ./bootstrap.sh --prefix=$INSTALLDIR/boost && ./b2 headers && ./b2 install toolset=gcc cxxflags=-std=c++11 --prefix=$INSTALLDIR/boost --with-atomic --with-chrono --with-date_time --with-filesystem --with-program_options --with-python --with-signals --with-test --with-thread -j $J -define=_GLIBCXX_USE_CXX11_ABI=1
    echo Installed Boost.Python.
else
    echo Boost.Python already installed.
fi

if [ ! -d $INSTALLDIR/openblas ]; then
    #
    # Install OpenBLAS
    #
    echo Installing OpenBLAS...
    mkdir -p $INSTALLDIR/openblas/
    cd $INSTALLDIR/openblas/ && git clone https://github.com/xianyi/OpenBLAS.git src && cd src && git checkout $OPENBLAS_VERSION
    cd $INSTALLDIR/openblas/src && $make -j $J && $make install PREFIX=$INSTALLDIR/openblas
    rm -rf $INSTALLDIR/openblas/src
    echo Installed OpenBLAS.
else
    echo OpenBlas already installed.
fi

if [ ! -d $INSTALLDIR/superlu ]; then
    #
    # Install SuperLU
    #
    echo Installing SuperLU...
    mkdir -p $INSTALLDIR/superlu/build
    cd $INSTALLDIR/superlu/ && git clone https://github.com/xiaoyeli/superlu.git src && cd src && git checkout $SUPERLU_VERSION
    cd $INSTALLDIR/superlu/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/superlu -DUSE_XSDK_DEFAULTS=TRUE -Denable_blaslib=OFF -DBLAS_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so ../src && $make -j $J && $make install
    rm -rf $INSTALLDIR/superlu/src
    echo Installed SuperLU.
else
    echo SuperLu already installed.
fi

if [ ! -d $INSTALLDIR/armadillo ]; then
    #
    # Install Armadillo
    #
    echo Installing Armadillo...
    mkdir -p $INSTALLDIR/armadillo/
    cd $INSTALLDIR/armadillo && wget http://sourceforge.net/projects/arma/files/armadillo-$ARMADILLO_VERSION.tar.xz && tar xf armadillo-$ARMADILLO_VERSION.tar.xz && rm armadillo-$ARMADILLO_VERSION.tar.xz
    cd $INSTALLDIR/armadillo/armadillo-$ARMADILLO_VERSION && ./configure && $cmake -DCMAKE_CXX_FLAGS=-D_-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLDIR/armadillo -Dopenblas_LIBRARY:FILEPATH=$INSTALLDIR/openblas/lib/libopenblas.so  -DSuperLU_INCLUDE_DIR:PATH=$INSTALLDIR/superlu/include -DSuperLU_LIBRARY:FILEPATH=$INSTALLDIR/superlu/lib64/libsuperlu.so	 && $make -j $J && $make install
    echo Installed Armadillo.
else
    echo Armadillo already installed.
fi

if [ ! -d $INSTALLDIR/cfitsio ]; then
    #
    # Install-cfitsio
    #
    echo Installing CFITSIO...
    mkdir -p ${INSTALLDIR}/cfitsio/build
    cd ${INSTALLDIR}/cfitsio && wget --retry-connrefused ftp://anonymous@heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio${CFITSIO_VERSION}.tar.gz
    cd ${INSTALLDIR}/cfitsio && tar xf cfitsio${CFITSIO_VERSION}.tar.gz
    cd ${INSTALLDIR}/cfitsio/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/cfitsio/ ../cfitsio
    cd ${INSTALLDIR}/cfitsio/build && $make -j ${J}
    cd ${INSTALLDIR}/cfitsio/build && $make install
    echo Installed CFITSIO.
else
    echo CFITSIO already installed.
fi

if [ ! -d $INSTALLDIR/wcslib ]; then
    #
    # Install-wcslib
    #
    echo Installing WCSLIB...
    mkdir ${INSTALLDIR}/wcslib
    if [ "${WCSLIB_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib.tar.bz2 -O wcslib-latest.tar.bz2; fi
    if [ "${WCSLIB_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib-${WCSLIB_VERSION}.tar.bz2; fi
    cd ${INSTALLDIR}/wcslib && tar xf wcslib-*.tar.bz2
    #cd ${INSTALLDIR} && mkdir wcslib && cd wcslib && svn checkout https://github.com/astropy/astropy/trunk/cextern/wcslib
    cd ${INSTALLDIR}/wcslib/wcslib* && ./configure --prefix=${INSTALLDIR}/wcslib --with-cfitsiolib=${INSTALLDIR}/cfitsio/lib/ --with-cfitsioinc=${INSTALLDIR}/cfitsio/include/ --without-pgplot
    cd ${INSTALLDIR}/wcslib/wcslib* && $make install -j $J
    echo Installed WCSLIB.
else
    echo WCSLIB already installed.
fi


# Make library and header directories easily available for future CMakes.
export CMAKE_INCLUDE=$INSTALLDIR/armadillo/include:$INSTALLDIR/boost/include:$INSTALLDIR/cfitsio/include:$INSTALLDIR/openblas/include:$INSTALLDIR/superlu/include:$INSTALLDIR/wcslib/include
export CMAKE_LIBRARY=$INSTALLDIR/armadillo/lib:$INSTALLDIR/boost/lib:$INSTALLDIR/cfitsio/lib:$INSTALLDIR/openblas/lib:$INSTALLDIR/superlu/lib:$INSTALLDIR/wcslib/lib
export CMAKE_PREFIX_PATH=$INSTALLDIR/armadillo:$INSTALLDIR/boost:$INSTALLDIR/casacore:$INSTALLDIR/cfitsio:$INSTALLDIR/dysco:$INSTALLDIR/openblas:$INSTALLDIR/superlu:$INSTALLDIR/wcslib

#########################################
# Install main LOFAR software packages. #
#########################################
export CPATH=$INSTALLDIR/armadillo/lib:$INSTALLDIR/boost/lib:$INSTALLDIR/cfitsio/lib:$INSTALLDIR/openblas/lib:$INSTALLDIR/superlu/lib:$INSTALLDIR/wcslib/lib
if [ ! -d $INSTALLDIR/casacore ]; then
    #
    # Install CASAcore
    #
    echo Installing CASAcore...
    mkdir -p ${INSTALLDIR}/casacore/build
    mkdir -p ${INSTALLDIR}/casacore/data
    cd $INSTALLDIR/casacore && git clone https://github.com/casacore/casacore.git src
    if [ "${CASACORE_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casacore/src && git checkout tags/${CASACORE_VERSION}; fi
    cd ${INSTALLDIR}/casacore/data && wget --retry-connrefused ftp://anonymous@ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar
    cd ${INSTALLDIR}/casacore/data && tar xf WSRT_Measures.ztar
    #cd ${INSTALLDIR}/casacore/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_CXX_FLAGS=-D_-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_LIBRARY_PATH=$CMAKE_LIBRARY -DCMAKE_INCLUDE_PATH=$CMAKE_INCLUDE -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDATA_DIR=${INSTALLDIR}/casacore/data -DWCSLIB_ROOT_DIR=/${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True -DHDF5_C_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5cc -DHDF5_CXX_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5++ -DHDF5_C_INCLUDE_DIR=$INSTALLDIR/hdf5/include -DHDF5_DIFF_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5diff -DHDF5_hdf5_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_LIBRARY_RELEASE=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_hl_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5_hl.so -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost/lib -DBOOST_INCLUDEDIR=$INSTALLDIR/boost/include -DBoost_DIR=$INSTALLDIR/boost -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DCXX11=ON ../src/
    #cd ${INSTALLDIR}/casacore/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_LIBRARY_PATH=$CMAKE_LIBRARY -DCMAKE_INCLUDE_PATH=$CMAKE_INCLUDE -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDATA_DIR=${INSTALLDIR}/casacore/data -DWCSLIB_ROOT_DIR=/${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost/lib -DBOOST_INCLUDEDIR=$INSTALLDIR/boost/include -DBoost_DIR=$INSTALLDIR/boost -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DCXX11=ON ../src/
    cd ${INSTALLDIR}/casacore/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_LIBRARY_PATH=$CMAKE_LIBRARY -DCMAKE_INCLUDE_PATH=$CMAKE_INCLUDE -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDATA_DIR=${INSTALLDIR}/casacore/data -DBoost_DIR=$INSTALLDIR/boost -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True -DCXX11=ON ../src/
    cd ${INSTALLDIR}/casacore/build && $make -j ${J}
    cd ${INSTALLDIR}/casacore/build && $make install
    echo Installed CASAcore.
else
    echo CASAcore already installed.
fi

if [ ! -d $INSTALLDIR/python-casacore ]; then
    #
    # Install-python-casacore
    #
    # Finding libraries is broken, patch the setup to include the previously installed boost and casacore libraries.
    export PYTHON_VERSION=2.7
    mkdir ${INSTALLDIR}/python-casacore
    cd ${INSTALLDIR}/python-casacore && git clone https://github.com/casacore/python-casacore
    if [ "$PYTHON_CASACORE_VERSION" != "latest" ]; then cd ${INSTALLDIR}/python-casacore/python-casacore && git checkout tags/${PYTHON_CASACORE_VERSION}; fi
    cd ${INSTALLDIR}/python-casacore/python-casacore && patch setup.py $PYTHON_CASACORE_PATCH && ./setup.py build_ext --swig-cpp --cython-cplus --pyrex-cplus -I${INSTALLDIR}/wcslib/include:${INSTALLDIR}/casacore/include/:${INSTALLDIR}/cfitsio/include:${INSTALLDIR}/boost/include -L${INSTALLDIR}/wcslib/lib:${INSTALLDIR}/casacore/lib/:${INSTALLDIR}/cfitsio/lib/:${INSTALLDIR}/boost/lib:/usr/lib64/
    mkdir -p ${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages/
    mkdir -p ${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages/
    export PYTHONPATH=${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages:${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages:$PYTHONPATH && cd ${INSTALLDIR}/python-casacore/python-casacore && ./setup.py install --prefix=${INSTALLDIR}/python-casacore/
else
    echo Python-CASAcore already installed.
fi

#
# Install CASArest
#
: '
echo Installing CASArest...
mkdir -p ${INSTALLDIR}/casarest/build
cd ${INSTALLDIR}/casarest && git clone https://github.com/casacore/casarest.git src
if [ "${CASAREST_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casarest/src && git checkout tags/${CASAREST_VERSION}; fi
#cd ${INSTALLDIR}/casarest/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_CXX_FLAGS=-D_-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casarest -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DCFITSIO_ROOT_DIR=$INSTALLDIR/cfitsio -DCfitsIO_DIR=$INSTALLDIR/cfitsio -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost -DBOOST_INCLUDEDIR=$INSTALLDIR/boost/include -DHDF5_C_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5cc -DHDF5_CXX_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5++ -DHDF5_C_INCLUDE_DIR=$INSTALLDIR/hdf5/include -DHDF5_DIFF_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5diff -DHDF5_hdf5_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_LIBRARY_RELEASE=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_hl_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5_hl.so ../src/
cd ${INSTALLDIR}/casarest/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casarest -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DCFITSIO_ROOT_DIR=$INSTALLDIR/cfitsio -DCfitsIO_DIR=$INSTALLDIR/cfitsio -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost -DBOOST_INCLUDEDIR=$INSTALLDIR/boost/include -DCXX11=ON ../src/
cd ${INSTALLDIR}/casarest/build && $make -j ${J}
cd ${INSTALLDIR}/casarest/build && $make install
echo Installed CASArest.
'

if [ ! -d $INSTALLDIR/dysco ]; then
    #
    # Install Dysco
    #
    echo Installing Dysco...
    mkdir -p $INSTALLDIR/dysco/build
    cd $INSTALLDIR/dysco && git clone https://github.com/aroffringa/dysco.git src
    #cd $INSTALLDIR/dysco/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_CXX_FLAGS=-D_-D_GLIBCXX_USE_CXX11_ABI=1 -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/dysco -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DCMAKE_LIBRARY_PATH=$CMAKE_LIBRARY -DCMAKE_INCLUDE_PATH=$CMAKE_INCLUDE -DHDF5_C_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5cc -DHDF5_CXX_COMPILER_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5++ -DHDF5_C_INCLUDE_DIR=$INSTALLDIR/hdf5/include -DHDF5_DIFF_EXECUTABLE=$INSTALLDIR/hdf5/bin/h5diff -DHDF5_hdf5_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_LIBRARY_RELEASE=$INSTALLDIR/hdf5/lib/libhdf5.so -DHDF5_hdf5_hl_LIBRARY=$INSTALLDIR/hdf5/lib/libhdf5_hl.so ../src && $make -j $J && $make install
    cd $INSTALLDIR/dysco/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/dysco -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DCMAKE_LIBRARY_PATH=$CMAKE_LIBRARY -DCMAKE_INCLUDE_PATH=$CMAKE_INCLUDE ../src && $make -j $J && $make install
    echo Installed Dysco.
else
    echo Dysco already installed.
fi

if [ ! -d $INSTALLDIR/aoflagger ]; then
    #
    # Install-aoflagger
    #
    mkdir -p ${INSTALLDIR}/aoflagger/build
    if [ "${AOFLAGGER_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/aoflagger && git clone git://git.code.sf.net/p/aoflagger/code aoflagger && cd ${INSTALLDIR}/aoflagger/aoflagger; fi
    if [ "${AOFLAGGER_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/aoflagger && git clone git://git.code.sf.net/p/aoflagger/code aoflagger && cd ${INSTALLDIR}/aoflagger/aoflagger && git checkout tags/${AOFLAGGER_VERSION}; fi
    export CMAKE_PREFIX_PATH=$INSTALLDIR/armadillo:$INSTALLDIR/boost:$INSTALLDIR/casacore:$INSTALLDIR/cfitsio:$INSTALLDIR/dysco:$INSTALLDIR/openblas:$INSTALLDIR/superlu:$INSTALLDIR/wcslib
    cd ${INSTALLDIR}/aoflagger/build && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger/ -DBUILD_SHARED_LIBS=ON -DPORTABLE=True ../aoflagger
    cd ${INSTALLDIR}/aoflagger/build && make -j ${J}
    cd ${INSTALLDIR}/aoflagger/build && make install
else
    echo AOFlagger already installed.
fi

if [ ! -d $INSTALLDIR/lofar ]; then
    #
    # Install-lofar
    #
    echo Installing LOFAR...
    mkdir -p ${INSTALLDIR}/lofar
    mkdir -p ${INSTALLDIR}/lofar/build
    mkdir -p ${INSTALLDIR}/lofar/build/gnucxx11_opt
    ls ${INSTALLDIR}
    ls ${INSTALLDIR}/lofar
    ls ${INSTALLDIR}/lofar/build/gnucxx11_opt
    if [ "${LOFAR_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/lofar && svn checkout https://svn.astron.nl/LOFAR/trunk src; fi
    if [ "${LOFAR_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/lofar && svn checkout https://svn.astron.nl/LOFAR/tags/LOFAR-Release-${LOFAR_VERSION} src; fi
    cd $INSTALLDIR/lofar && svn update --depth=infinity $INSTALLDIR/lofar/src/CMake
    patch $INSTALLDIR/lofar/src/CMake/variants/GNUCXX11.cmake $PATCH_LOFAR
    #cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DUSE_LOG4CPLUS=OFF -DPYTHON_BDSF=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ -DUSE_OPENMP=True -DBUILD_Imager=OFF -DBUILD_ACC=OFF -DBUILD_ALC=OFF -DBUILD_AMC=OFF -DBUILD_LCS=OFF -DBUILD_ApplCommon=OFF -DBUILD_BBSControl=OFF -DBUILD_BBSKernel=OFF -DBUILD_BBSTools=OFF -DBUILD_CEP=OFF -DBUILD_Calibration=OFF -DBUILD_Common=OFF -DBUILD_DOCUMENTATION=OFF -DBUILD_DAL=OFF -DBUILD_DP3=OFF -DBUILD_DPPP=OFF -DBUILD_Docker=OFF -DBUILD_ElementResponse=OFF -DBUILD_ExpIon=OFF -DBUILD_GSM=OFF -DBUILD_LAPS=OFF -DBUILD_LMWCommon=OFF -DBUILD_LofarStMan=OFF -DBUILD_MS=OFF -DBUILD_MSLofar=OFF -DBUILD_MessageBus=OFF -DBUILD_OTDB_Services=OFF -DBUILD_PLC=OFF -DBUILD_ParmDB=ON -DBUILD_Pipeline=ON -DBUILD_PyBDSM=ON -DBUILD_PyCommon=OFF -DBUILD_PyMessaging=OFF -DBUILD_PythonDPPP=OFF -DBUILD_SHARED_LIBS=ON -DBUILD_SPW_Combine=OFF -DBUILD_STATIC_EXECUTABLES=OFF -DBUILD_StaticMetaData=OFF -DBUILD_StationResponse=ON -DBUILD_TESTING=ON -DBUILD_TestDynDPPP=OFF -DBUILD_Transport=OFF -DBUILD_pyparameterset=OFF -DBUILD_pyparmdb=OFF -DBUILD_pystationresponse=ON -DBUILD_pytools=OFF ${INSTALLDIR}/lofar/src/
    #cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DBUILD_PACKAGES=StationResponse -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DUSE_LOG4CPLUS=OFF -DUSE_OPENMP=True ${INSTALLDIR}/lofar/src/
    export CMAKE_PREFIX_PATH=$INSTALLDIR/aoflagger:$INSTALLDIR/armadillo:$INSTALLDIR/boost:$INSTALLDIR/casacore:$INSTALLDIR/casarest:$INSTALLDIR/cfitsio:$INSTALLDIR/dysco:$INSTALLDIR/openblas:$INSTALLDIR/superlu:$INSTALLDIR/wcslib
    export PYTHONPATH=$INSTALLDIR/python-casacore/lib64/python2.7/site-packages:$PYTHONPATH
    #cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DBUILD_PACKAGES=Offline -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DUSE_LOG4CPLUS=OFF -DUSE_OPENMP=True -DBUILD_BBSTools=OFF -DBUILD_Imager=OFF ${INSTALLDIR}/lofar/src/
    # Build only the StationResponse library needed for NDPPP.
    #cd $INSTALLDIR/lofar/build/gnucxx11_opt && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DBUILD_PACKAGES="MS StationResponse pystationresponse ParmDB pyparmdb Pipeline" -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DUSE_LOG4CPLUS=OFF -DUSE_OPENMP=True ${INSTALLDIR}/lofar/src/
    cd $INSTALLDIR/lofar/build/gnucxx11_opt && $cmake -DCMAKE_CXX_FLAGS=-D_GLIB_USE_CXX_ABI=1 -DBUILD_PACKAGES="MS pystationresponse ParmDB pyparmdb Pipeline" -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DUSE_LOG4CPLUS=OFF -DUSE_OPENMP=True ${INSTALLDIR}/lofar/src/
    cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && $make -j $J && $make install
    echo Installed LOFAR.
else
    echo LOFAR already installed.
fi

if [ ! -d $INSTALLDIR/LOFARBeam ]; then
    #
    # Install the standalone StationResponse libraries.
    #
    echo Installing LOFARBeam...
    mkdir -p $INSTALLDIR/LOFARBeam/build
    cd $INSTALLDIR/LOFARBeam
    git clone https://github.com/lofar-astron/LOFARBeam.git src
    cd build && $cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/LOFARBeam ../src && $make -j12 && $make install
fi

#
# Install DPPP.
#
if [ ! -d $INSTALLDIR/DPPP ]; then
    echo Installing DPPP...
    export CMAKE_PREFIX_PATH=$INSTALLDIR/aoflagger:$INSTALLDIR/armadillo:$INSTALLDIR/boost:$INSTALLDIR/casacore:$INSTALLDIR/cfitsio:$INSTALLDIR/superlu:$INSTALLDIR/lofar:$INSTALLDIR/LOFARBeam
    export LD_LIBRARY_PATH=$INSTALLDIR/superlu/lib64:$INSTALLDIR/LOFARBeam/lib:$LD_LIBRARY_PATH
    mkdir -p $INSTALLDIR/DPPP/build
    git clone https://github.com/lofar-astron/DP3.git $INSTALLDIR/DPPP/src
    cd $INSTALLDIR/DPPP/build
    $cmake -DCMAKE_CXX_FLAGS="-D_GLIB_USE_CXX_ABI=1 -DBOOST_NO_CXX11_SCOPED_ENUMS" -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLDIR/DPPP -DLOFAR_STATION_RESPONSE_DIR:PATH=$INSTALLDIR/LOFARBeam/include -DLOFAR_STATION_RESPONSE_LIB:FILEPATH=$INSTALLDIR/LOFARBeam/lib/libstationresponse.so ../src
    make -j $J && make install
    echo Installed DPPP.
else
    echo DPPP already installed.
fi

if [ ! -d $INSTALLDIR/idg ]; then
    echo Installing IDG.
    #
    # Install Image Domain Gridder (IDG)
    #
    mkdir -p $INSTALLDIR/idg && cd $INSTALLDIR/idg
    git clone https://gitlab.com/astron-idg/idg.git src
    cd src && mkdir build && cd build
    $cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/idg ..
    make -j $J
    make install
else
    echo IDG already installed.
fi

if [ ! -d $INSTALLDIR/wsclean ]; then
    echo Installing WSClean.
    #
    # Install-WSClean
    #
    export CPATH=${INSTALLDIR}/casacore/include:$INSTALLDIR/LOFARBeam/include:$CPATH
    export CMAKE_PREFIX_PATH=$INSTALLDIR/armadillo:$INSTALLDIR/boost:$INSTALLDIR/casacore:$INSTALLDIR/cfitsio:$INSTALLDIR/dysco:$INSTALLDIR/idg:$INSTALLDIR/lofar:$INSTALLDIR/LOFARBeam:$INSTALLDIR/openblas:$INSTALLDIR/superlu:$INSTALLDIR/wcslib
    mkdir ${INSTALLDIR}/wsclean
    if [ "$WSCLEAN_VERSION" != "latest" ]; then cd ${INSTALLDIR}/wsclean && wget http://downloads.sourceforge.net/project/wsclean/wsclean-${WSCLEAN_VERSION}/wsclean-${WSCLEAN_VERSION}.tar.bz2 && tar -xjf wsclean-${WSCLEAN_VERSION}.tar.bz2 && cd wsclean-${WSCLEAN_VERSION}; fi
    if [ "$WSCLEAN_VERSION" = "latest" ]; then cd ${INSTALLDIR}/wsclean && git clone git://git.code.sf.net/p/wsclean/code src && cd src/wsclean; fi
    mkdir build && cd build && $cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/wsclean -DLOFAR_STATION_RESPONSE_DIR:PATH=$INSTALLDIR/LOFARBeam/include -DLOFAR_STATION_RESPONSE_LIB:FILEPATH=$INSTALLDIR/LOFARBeam/lib/libstationresponse.so ..
    make -j ${J}
    make install
else
    echo WSClean already installed.
fi

if [ ! -d $INSTALLDIR/RMextract ]; then
    #
    # Install-RMextract
    #
    export PYTHONPATH=$INSTALLDIR/RMextract/lib64/python2.7/site-packages:$PYTHONPATH
    echo ${PYTHONPATH}
    mkdir ${INSTALLDIR}/RMextract
    mkdir ${INSTALLDIR}/RMextract/build
    mkdir ${INSTALLDIR}/RMextract/lib64
    mkdir ${INSTALLDIR}/RMextract/lib64/python2.7
    mkdir ${INSTALLDIR}/RMextract/lib64/python2.7/site-packages
    cd ${INSTALLDIR}/RMextract/build && git clone https://github.com/lofar-astron/RMextract.git src && cd src && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/RMextract
else
    echo RMextract already installed.
fi

if [ ! -d $INSTALLDIR/losoto ]; then
    echo Installing LoSoTo.
    #
    # Install-LoSoTo
    #
    export PYTHONPATH=$INSTALLDIR/losoto/lib/python2.7/site-packages/:$PYTHONPATH
    mkdir ${INSTALLDIR}/losoto
    mkdir ${INSTALLDIR}/losoto/build
    mkdir ${INSTALLDIR}/losoto/lib
    mkdir ${INSTALLDIR}/losoto/lib/python2.7
    mkdir ${INSTALLDIR}/losoto/lib/python2.7/site-packages
    export PYTHONPATH=$INSTALLDIR/losoto/lib/python2.7/site-packages:$PYTHONPATH
    cd ${INSTALLDIR}/losoto/build && git clone https://github.com/revoltek/losoto.git src && cd src && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/losoto
else
    echo LoSoTo already installed.
fi

if [ ! -d $INSTALLDIR/lsmtool ]; then
    echo Installing LSMTool.
    #
    # Install LSMTool.
    #
    mkdir -p $INSTALLDIR/lsmtool/lib/python2.7/site-packages
    export PYTHONPATH=$INSTALLDIR/lsmtool/lib/python2.7/site-packages:$PYTHONPATH
    cd $INSTALLDIR/lsmtool && git clone https://github.com/darafferty/LSMTool.git lsmtool
    cd $INSTALLDIR/lsmtool/lsmtool && python setup.py install --prefix=$INSTALLDIR/lsmtool
else
    echo LSMTool already installed.
fi

###############################
# Finish up the installation. #
###############################
echo "Installation directory contents:"
ls ${INSTALLDIR}
#
# init-lofar
#
echo export INSTALLDIR=$INSTALLDIR > $INSTALLDIR/init.sh
echo module load gcc/8.1.0 >> $INSTALLDIR/init.sh
echo source \$INSTALLDIR/lofar/lofarinit.sh  >> $INSTALLDIR/init.sh

ln -s $INSTALLDIR/DPPP/bin/DPPP $INSTALLDIR/lofar/bin/NDPPP

echo export PYTHONPATH=\$INSTALLDIR/lofar/lib64/python2.7/site-packages/:\$INSTALLDIR/losoto/lib/python2.7/site-packages/:\$INSTALLDIR/lsmtool/lib/python2.7/site-packages/:\$INSTALLDIR/pybdsf/lib/python2.7/site-packages:\$INSTALLDIR/pybdsf/lib/python2.7/site-packages:\$INSTALLDIR/python-casacore/lib/python2.7/site-packages/:\$INSTALLDIR/python-casacore/lib64/python2.7/site-packages/:\$INSTALLDIR/python-casacore/lib/python2.7/site-packages/:\$INSTALLDIR/DPPP/lib64/python2.7/site-packages/:\$PYTHONPATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/aoflagger/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/casacore/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/DPPP/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/dysco/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/losoto/bin:\$PATH >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/pybdsf/bin:\$PATH >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/wsclean/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export LD_LIBRARY_PATH=\$INSTALLDIR/aoflagger/lib:\$INSTALLDIR/armadillo/lib64:\$INSTALLDIR/boost/lib:\$INSTALLDIR/casacore/lib:\$INSTALLDIR/cfitsio/lib:\$INSTALLDIR/DPPP/lib:\$INSTALLDIR/dysco/lib:\$INSTALLDIR/lofar/lib64:\$INSTALLDIR/LOFARBeam/lib:\$INSTALLDIR/superlu/lib64:\$INSTALLDIR/wcslib/:\$LD_LIBRARY_PATH  >> $INSTALLDIR/init.sh
#echo export LD_LIBRARY_PATH=\$INSTALLDIR/aoflagger/lib:\$INSTALLDIR/armadillo/lib64:\$INSTALLDIR/boost/lib:\$INSTALLDIR/casacore/lib:\$INSTALLDIR/cfitsio/lib:\$INSTALLDIR/DPPP/lib:\$INSTALLDIR/dysco/lib:\$INSTALLDIR/superlu/lib64:\$INSTALLDIR/wcslib/:\$LD_LIBRARY_PATH  >> $INSTALLDIR/init.sh

