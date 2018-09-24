# General environment settings.
export J=60
export INSTALLDIR=/install/directory/base
export PYTHON_VERSION=2.7
# Source additional environment stuff here if necessary, e.g. Python virtualenvs.

# Path to where the patch for python-casacore's setup is stored.
export PYTHON_CASACORE_PATCH=/path/to/patch/python_casacore_setup_patch.patch

# Settings relevant to the installed software.
export AOFLAGGER_VERSION=latest
export ARMADILLO_VERSION=8.600.0
export BLAS_VERSION=0.2.17
#export BOOST_VERSION=1.60.0
export BOOST_DOT_VERSION=1.63.0
export BOOST_VERSION=1_63_0
export CASACORE_VERSION=v2.4.1
# Leave at latest, release versions crash for some reason.
export CASAREST_VERSION=latest
export CFITSIO_VERSION=3410
export DYSCO_VERSION=v1.0.1
export FFTW_VERSION=3.3.4
export GLS_VERSION=1.15
export HDF5_VERSION=1.10.1
export LAPACK_VERSION=3.6.0
export LOFAR_VERSION=3_1_4
export LOG4CPLUS_VERSION=1.1.x
export LOSOTO_VERSION=2.0
export LSMTOOL_VERSION=v1.2.0
export OPENBLAS_VERSION=v0.3.2
export PYBDSF_VERSION=v1.8.12
#export PYTHON_CASACORE_VERSION=v2.1.2
export PYTHON_CASACORE_VERSION=v2.2.1
export RMEXTRACT_VERSION=v0.1
# Do not change, Armadillo wants this version of SuperLU.
export SUPERLU_VERSION=v5.2.1
export UNITTEST2_VERSION=1.1.0
export XMLRUNNER_VERSION=1.7.7
export WSCLEAN_VERSION=2.4
export WCSLIB_VERSION=5.18

####################################
# DO NOT MODIFY BELOW THIS LINE    #
# ANYTHING CHANGEABLE IS ABOVE     #
# Requirements:                    #
# CMAKE 3 available through cmake3 #
# patch available through patch    #
####################################

mkdir -p $INSTALLDIR
#
# Install Boost.Python
#
mkdir -p $INSTALLDIR/boost/src
cd $INSTALLDIR && wget https://dl.bintray.com/boostorg/release/${BOOST_DOT_VERSION}/source/boost_${BOOST_VERSION}.tar.gz
cd $INSTALLDIR && tar xzf boost_${BOOST_VERSION}.tar.gz -C boost && cd boost/boost_${BOOST_VERSION} && ./bootstrap.sh --prefix=$INSTALLDIR/boost && ./b2 install --prefix=$INSTALLDIR/boost --with=all -j $J

#
# Install OpenBLAS
#
mkdir -p $INSTALLDIR/openblas/
cd $INSTALLDIR/openblas/ && git clone https://github.com/xianyi/OpenBLAS.git src && cd src && git checkout $OPENBLAS_VERSION
cd $INSTALLDIR/openblas/src && make && make install PREFIX=$INSTALLDIR/openblas
rm -rf $INSTALLDIR/openblas/src

#
# Install SuperLU
#
mkdir -p $INSTALLDIR/superlu/build
cd $INSTALLDIR/superlu/ && git clone https://github.com/xiaoyeli/superlu.git src && cd src && git checkout $SUPERLU_VERSION
cd $INSTALLDIR/superlu/build && cmake ../src -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/superlu -DUSE_XSDK_DEFAULTS=TRUE -Denable_blaslib=OFF -DBLAS_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so && make && make install
rm -rf $INSTALLDIR/superlu/src

#
# Install Armadillo
#
mkdir -p $INSTALLDIR/armadillo/
cd $INSTALLDIR/armadillo && wget http://sourceforge.net/projects/arma/files/armadillo-$ARMADILLO_VERSION.tar.xz && tar xf armadillo-$ARMADILLO_VERSION.tar.xz && rm armadillo-$ARMADILLO_VERSION.tar.xz
cd $INSTALLDIR/armadillo/armadillo-$ARMADILLO_VERSION && ./configure && cmake . -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLDIR/armadillo -Dopenblas_LIBRARY:FILEPATH=$INSTALLDIR/openblas/lib/libopenblas.so  -DSuperLU_INCLUDE_DIR:PATH=$INSTALLDIR/superlu/include -DSuperLU_LIBRARY:FILEPATH=$INSTALLDIR/superlu/lib64/libsuperlu.so && make && make install


#
# install-cfitsio
#
mkdir -p ${INSTALLDIR}/cfitsio/build
cd ${INSTALLDIR}/cfitsio && wget --retry-connrefused ftp://anonymous@heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio${CFITSIO_VERSION}.tar.gz
cd ${INSTALLDIR}/cfitsio && tar xf cfitsio${CFITSIO_VERSION}.tar.gz
cd ${INSTALLDIR}/cfitsio/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/cfitsio/ ../cfitsio
cd ${INSTALLDIR}/cfitsio/build && make -j ${J}
cd ${INSTALLDIR}/cfitsio/build && make install

#
# install-wcslib
#
mkdir ${INSTALLDIR}/wcslib
if [ "${WCSLIB_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib.tar.bz2 -O wcslib-latest.tar.bz2; fi
if [ "${WCSLIB_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib-${WCSLIB_VERSION}.tar.bz2; fi
cd ${INSTALLDIR}/wcslib && tar xf wcslib-*.tar.bz2
#cd ${INSTALLDIR} && mkdir wcslib && cd wcslib && svn checkout https://github.com/astropy/astropy/trunk/cextern/wcslib
cd ${INSTALLDIR}/wcslib/wcslib* && ./configure --prefix=${INSTALLDIR}/wcslib --with-cfitsiolib=${INSTALLDIR}/cfitsio/lib/ --with-cfitsioinc=${INSTALLDIR}/cfitsio/include/ --without-pgplot
cd ${INSTALLDIR}/wcslib/wcslib* && make -j $J
cd ${INSTALLDIR}/wcslib/wcslib* && make install
#yum -y install wcslib wcslib-devel

#
# Install HDF5
#
#mkdir -p ${INSTALLDIR}/hdf5
#cd ${INSTALLDIR}/hdf5 && wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz
#cd ${INSTALLDIR}/hdf5 && tar xf hdf5*.tar.gz
#cd ${INSTALLDIR}/hdf5/hdf5*/ && ./configure --prefix=${INSTALLDIR}/hdf5 --enable-fortran --enable-threadsafe --enable-cxx --with-pthread --enable-linux-lfs --enable-unsupported
#cd ${INSTALLDIR}/hdf5/hdf5*/ && make -j ${J}
#cd ${INSTALLDIR}/hdf5/hdf5*/ && make install

#
# Install CASAcore
#
mkdir -p ${INSTALLDIR}/casacore/build
mkdir -p ${INSTALLDIR}/casacore/data
cd $INSTALLDIR/casacore && git clone https://github.com/casacore/casacore.git src
if [ "${CASACORE_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casacore/src && git checkout tags/${CASACORE_VERSION}; fi
cd ${INSTALLDIR}/casacore/data && wget --retry-connrefused ftp://anonymous@ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar
cd ${INSTALLDIR}/casacore/data && tar xf WSRT_Measures.ztar
cd ${INSTALLDIR}/casacore/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DDATA_DIR=${INSTALLDIR}/casacore/data -DWCSLIB_ROOT_DIR=/${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost_1_63_0/lib -DBOOST_INCLUDEDIR=$INSTALLDIR/boost_1_63_0/include -DBoost_DIR=$INSTALLDIR/boost_1_63_0 -DBoost_INCLUDE_DIR=$INSTALLDIR/boost_1_63_0/include -DBoost_LIBRARY_DIR=$INSTALLDIR/boost_1_63_0/lib ../src/ 
cd ${INSTALLDIR}/casacore/build && make -j ${J}
cd ${INSTALLDIR}/casacore/build && make install

#
# Install CASArest
#
mkdir -p ${INSTALLDIR}/casarest/build
cd ${INSTALLDIR}/casarest && git clone https://github.com/casacore/casarest.git src
if [ "${CASAREST_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casarest/src && git checkout tags/${CASAREST_VERSION}; fi
cd ${INSTALLDIR}/casarest/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casarest -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DCFITSIO_ROOT_DIR=$INSTALLDIR/cfitsio -DCfitsIO_DIR=$INSTALLDIR/cfitsio -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBOOST_LIBRARYDIR=$INSTALLDIR/boost_1_63_0 -DBOOST_INCLUDEDIR=$INSTALLDIR/boost_1_63_0/include ../src/
cd ${INSTALLDIR}/casarest/build && make -j ${J}
cd ${INSTALLDIR}/casarest/build && make install

#
# install-python-casacore
#
# Finding libraries is broken, patch the setup to include the previously installed boost and casacore libraries.
export PYTHON_VERSION=2.7
mkdir ${INSTALLDIR}/python-casacore
cd ${INSTALLDIR}/python-casacore && git clone https://github.com/casacore/python-casacore
if [ "$PYTHON_CASACORE_VERSION" != "latest" ]; then cd ${INSTALLDIR}/python-casacore/python-casacore && git checkout tags/${PYTHON_CASACORE_VERSION}; fi
cd ${INSTALLDIR}/python-casacore/python-casacore && patch setup.py $PYTHON_CASACORE_PATCH && ./setup.py build_ext -I${INSTALLDIR}/wcslib/include:${INSTALLDIR}/casacore/include/:${INSTALLDIR}/cfitsio/include:${INSTALLDIR}/boost_1_63_0/include -L${INSTALLDIR}/wcslib/lib:${INSTALLDIR}/casacore/lib/:${INSTALLDIR}/cfitsio/lib/:${INSTALLDIR}/boost_1_63_0/lib:/usr/lib64/
mkdir -p ${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages/
mkdir -p ${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages/
export PYTHONPATH=${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages:${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages:$PYTHONPATH && cd ${INSTALLDIR}/python-casacore/python-casacore && ./setup.py install --prefix=${INSTALLDIR}/python-casacore/

#
# Install Dysco
#
mkdir -p $INSTALLDIR/dysco/build
cd $INSTALLDIR/dysco && git clone https://github.com/aroffringa/dysco.git src
cd $INSTALLDIR/dysco/build && cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/dysco -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include ../src && make -j $J && make install

#
# install-log4cplus
#
mkdir -p ${INSTALLDIR}/log4cplus/build
if [ "${LOG4CPLUS_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/log4cplus && git clone --recursive https://github.com/log4cplus/log4cplus.git src; fi
if [ "${LOG4CPLUS_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/log4cplus && git clone --recursive https://github.com/log4cplus/log4cplus.git src && cd src && git checkout ${LOG4CPLUS_VERSION}; fi
cd ${INSTALLDIR}/log4cplus/build && cmake3 -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/log4cplus ../src/
cd ${INSTALLDIR}/log4cplus/build && make -j ${J}
cd ${INSTALLDIR}/log4cplus/build && make install
module unload cmake/3.9

#
# install-aoflagger
#
mkdir -p ${INSTALLDIR}/aoflagger/build
if [ "${AOFLAGGER_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/aoflagger && git clone git://git.code.sf.net/p/aoflagger/code aoflagger && cd ${INSTALLDIR}/aoflagger/aoflagger; fi
if [ "${AOFLAGGER_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/aoflagger && git clone git://git.code.sf.net/p/aoflagger/code aoflagger && cd ${INSTALLDIR}/aoflagger/aoflagger && git checkout tags/${AOFLAGGER_VERSION}; fi
cd ${INSTALLDIR}/aoflagger/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio -DBUILD_SHARED_LIBS=ON -DBOOST_INCLUDEDIR=$INSTALLDIR/boost_1_63_0/include -DBOOST_LIBRARYDIR=$INSTALLDIR/boost_1_63_0/lib -DBOOST_ROOT=$INSTALLDIR/boost_1_63_0/ -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DBLAS_atlas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBLAS_f77blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBLAS_goto2_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DPORTABLE=True ../aoflagger
cd ${INSTALLDIR}/aoflagger/build && make -j ${J}
cd ${INSTALLDIR}/aoflagger/build && make install

#
# install-pybdsf
#
mkdir -p ${INSTALLDIR}/pybdsf
if [ "${PYBDSF_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/pybdsf && git clone https://github.com/lofar-astron/pybdsf pybdsf && cd pybdsf; fi
if [ "${PYBDSF_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/pybdsf && git clone https://github.com/lofar-astron/pybdsf && cd ${INSTALLDIR}/pybdsf/pybdsf && git checkout tags/${PYBDSF_VERSION}; fi
mkdir -p ${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ && mkdir -p ${INSTALLDIR}/pybdsf/lib64/python${PYTHON_VERSION}/site-packages/ && export PYTHONPATH=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages:${INSTALLDIR}/pybdsf/lib64/python${PYTHON_VERSION}/site-packages:$PYTHONPATH && cd ${INSTALLDIR}/pybdsf/pybdsf && python setup.py install --prefix=${INSTALLDIR}/pybdsf/
#pip install https://github.com/lofar-astron/PyBDSF/archive/v1.8.14.tar.gz

#
# install-LSMTool
#
mkdir -p ${INSTALLDIR}/LSMTool && \
    cd ${INSTALLDIR}/LSMTool && git clone https://github.com/darafferty/LSMTool.git && \
    cd ${INSTALLDIR}/LSMTool/LSMTool && \
    mkdir -p ${INSTALLDIR}/LSMTool/lib/python${PYTHON_VERSION}/site-packages/ && \
    export PYTHONPATH=${PYTHONPATH}:${INSTALLDIR}/LSMTool/lib/python${PYTHON_VERSION}/site-packages/ && \
    python setup.py install --prefix=${INSTALLDIR}/LSMTool # && \
    # bash -c "find ${INSTALLDIR}/LSMTool/lib -name '*.so' | xargs strip || true" && \
    # bash -c "rm -rf ${INSTALLDIR}/LSMTool/LSMTool"

#
# install-lofar
#
mkdir -p ${INSTALLDIR}/lofar
mkdir -p ${INSTALLDIR}/lofar/build
mkdir -p ${INSTALLDIR}/lofar/build/gnucxx11_opt
ls ${INSTALLDIR}
ls ${INSTALLDIR}/lofar
ls ${INSTALLDIR}/lofar/build/gnucxx11_opt
if [ "${LOFAR_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/lofar && svn checkout https://svn.astron.nl/LOFAR/trunk src; fi
if [ "${LOFAR_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/lofar && svn checkout https://svn.astron.nl/LOFAR/tags/LOFAR-Release-${LOFAR_VERSION} src; fi
cd $INSTALLDIR/lofar && svn update --depth=infinity $INSTALLDIR/lofar/src/CMake
cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && cmake -DBUILD_PACKAGES=Offline -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/  -DCASAREST_ROOT_DIR=${INSTALLDIR}/casarest/ -DAOFLAGGER_LIBRARY=$INSTALLDIR/aoflagger/lib/libaoflagger.so -DAOFLAGGER_LIBRARY_DIR=${INSTALLDIR}/aoflagger/lib -DAOFLAGGER_INCLUDE_DIR=$INSTALLDIR/aoflagger/include -DLOG4CPLUS_ROOT_DIR=${INSTALLDIR}/log4cplus/ -DPYTHON_BDSF=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ -DUSE_OPENMP=True -DBUILD_Imager=OFF -DBLAS_blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBLAS_f77blas_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBLAS_goto2_LIBRARY=$INSTALLDIR/openblas/lib/libopenblas.so -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include ${INSTALLDIR}/lofar/src/
cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && make -j $J && make install

#
# install-WSClean
#
export CPATH=${INSTALLDIR}/casacore/include:$CPATH
mkdir ${INSTALLDIR}/wsclean
cd ${INSTALLDIR}/wsclean && wget http://downloads.sourceforge.net/project/wsclean/wsclean-${WSCLEAN_VERSION}/wsclean-${WSCLEAN_VERSION}.tar.bz2 && tar -xjf wsclean-${WSCLEAN_VERSION}.tar.bz2 && cd wsclean-${WSCLEAN_VERSION} && ls && mkdir build && cd build && ls && cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/wsclean -DCMAKE_PREFIX_PATH="${INSTALLDIR}/casacore;${INSTALLDIR}/cfitsio;${INSTALLDIR}/lofar" && make -j ${J} && make install
ls ${INSTALLDIR}

#
# install-Dysco
#
mkdir ${INSTALLDIR}/dysco 
cd ${INSTALLDIR}/dysco && git clone https://github.com/aroffringa/dysco.git && cd ${INSTALLDIR}/dysco/dysco && ls && mkdir build && cd build && ls && cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/dysco -DCMAKE_PREFIX_PATH="${INSTALLDIR}/casacore;${INSTALLDIR}/cfitsio;${INSTALLDIR}/lofar" && make -j ${J} && make install
ls ${INSTALLDIR}

#
# install-RMextract
#
export PYTHONPATH=$INSTALLDIR/RMextract/lib64/python2.7/site-packages:$PYTHONPATH
echo ${PYTHONPATH}
mkdir ${INSTALLDIR}/RMextract
mkdir ${INSTALLDIR}/RMextract/build
mkdir ${INSTALLDIR}/RMextract/lib64
mkdir ${INSTALLDIR}/RMextract/lib64/python2.7
mkdir ${INSTALLDIR}/RMextract/lib64/python2.7/site-packages
cd ${INSTALLDIR}/RMextract/build && git clone https://github.com/lofar-astron/RMextract.git src && cd src && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/RMextract
ls ${INSTALLDIR}

#
# Install-Losoto
#
export PYTHONPATH=/opt/lofar/losoto/lib/python2.7/site-packages/:$PYTHONPATH
mkdir ${INSTALLDIR}/losoto
mkdir ${INSTALLDIR}/losoto/build
mkdir ${INSTALLDIR}/losoto/lib
mkdir ${INSTALLDIR}/losoto/lib/python2.7
mkdir ${INSTALLDIR}/losoto/lib/python2.7/site-packages
export PYTHONPATH=$INSTALLDIR/losoto/lib/python2.7/site-packages:$PYTHONPATH
cd ${INSTALLDIR}/losoto/build && git clone https://github.com/revoltek/losoto.git src && cd src && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/losoto

#
# Install LSMTool.
#
mkdir -p $INSTALLDIR/lsmtool/lib/python2.7/site-packages
export PYTHONPATH=$INSTALLDIR/lsmtool/lib/python2.7/site-packages:$PYTHONPATH
cd $INSTALLDIR/lsmtool && git clone https://github.com/darafferty/LSMTool.git lsmtool
cd $INSTALLDIR/lsmtool/lsmtool && python setup.py install --prefix=$INSTALLDIR/lsmtool

#
# Install WSClean
#
mkdir -p $INSTALLDIR/wsclean
cd $INSTALLDIR/wsclean && wget https://sourceforge.net/projects/wsclean/files/wsclean-${WSCLEAN_VERSION}/wsclean-${WSCLEAN_VERSION}.tar.bz2
tar xf wsclean-${WSCLEAN_VERSION}.tar.bz2
mkdir build && cd build && cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/wsclean -DCMAKE_PREFIX_PATH=$INSTALLDIR/lofar -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DBoost_LIBRARY_DIR=$INSTALLDIR/boost/lib -DBoost_INCLUDE_DIR=$INSTALLDIR/boost/include -DCFITSIO_LIBRARY=$INSTALLDIR/cfitsio/lib/libcfitsio.so -DCFITSIO_INCLUDE_DIR=$INSTALLDIR/cfitsio/include -DPORTABLE=True ../wsclean-${WSCLEAN_VERSION}
make -j $J && make install

echo "Installation directory contents:"
ls ${INSTALLDIR}

#
# init-lofar
#
echo export INSTALLDIR=$INSTALLDIR > $INSTALLDIR/init.sh
echo source \$INSTALLDIR/lofar/lofarinit.sh  >> $INSTALLDIR/init.sh
echo export PYTHONPATH=\$INSTALLDIR/pybdsf/lib/python2.7/site-packages:\$INSTALLDIR/pybdsf/lib/python2.7/site-packages:\$INSTALLDIR/python-casacore/lib/python2.7/site-packages/:\$INSTALLDIR/python-casacore/lib64/python2.7/site-packages/:\$INSTALLDIR/python-casacore/lib/python2.7/site-packages/:\$PYTHONPATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/casacore/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/dysco/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/losoto/bin:\$PATH >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/pybdsf/bin:\$PATH >> $INSTALLDIR/init.sh
echo export PATH=\$INSTALLDIR/wsclean/bin:\$PATH  >> $INSTALLDIR/init.sh
echo export PATH=/net/lofar1/data1/rvweeren/software/wsclean-code-2.6june27portable/wsclean/build/:\$PATH
echo export LD_LIBRARY_PATH=\$INSTALLDIR/armadillo/lib64:\$INSTALLDIR/casacore/lib:\$INSTALLDIR/cfitsio/lib:\$INSTALLDIR/dysco/lib:\$INSTALLDIR/superlu/lib64:\$INSTALLDIR/wcslib/:\$LD_LIBRARY_PATH  >> $INSTALLDIR/init.sh
