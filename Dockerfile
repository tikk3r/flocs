#
# base
#
FROM centos:7
#FROM lofar-base-c7:lofar-2_19_0

# UPDATES
#  14-06-2018 JBRO: added base and lofex into one Dockerfile
#  14-06-2018 JBRO: added --no-deps to astropy pip install

#
# common-environment
#
ENV USER lofar
ENV INSTALLDIR /opt/${USER}/
#ENV INSTALLDIR=/opt

#
# environment
#
ENV PYTHON_VERSION 2.7

#
# versions
#
ENV CFITSIO_VERSION 3410
ENV WCSLIB_VERSION 5.20
ENV CASACORE_VERSION v2.3.0
#ENV CASAREST_VERSION v1.4.1
ENV PYTHON_CASACORE_VERSION v2.1.2
ENV PYBDSF_VERSION v1.8.12
ENV LSMTOOL_VERSION v1.2.0
ENV AOFLAGGER_VERSION v2.8.0
#ENV LOFAR_VERSION 2_21_4
#ENV LOFAR_VERSION 2_20_2
#ENV LOFAR_VERSION 2_19_0
ENV LOFAR_VERSION 3_2_2
ENV WSCLEAN_VERSION 2.6
ENV LOG4CPLUS_VERSION 1.1.x
#ENV GCC_VERSION 4.9.3
ENV GCC_VERSION 5.4.0
ENV BOOST_VERSION 1.63.0
#ENV HDF5_VERSION 1.10.1
ENV BLAS_VERSION 0.2.17
ENV LAPACK_VERSION 3.6.0
ENV FFTW_VERSION 3.3.4
ENV GSL_VERSION 1.15
ENV XMLRUNNER_VERSION 1.7.7
ENV MONETDB_VERSION 11.19.3.2
ENV UNITTEST2_VERSION 1.1.0
ENV PYFITS_VERSION 3.3
ENV PYWCS_VERSION 1.12
ENV WSCLEAN_VERSION 2.4
ENV DYSCO_VERSION v1.0.1
ENV RMEXTRACT_VERSION v0.1
ENV LOSOTO_VERSION 1.0

#
# build environment
#
ENV J 2


#
# base
#
RUN yum -y remove iputils
RUN yum -y update
RUN yum -y install sudo
RUN yum -y install git svn wget 
RUN yum -y install automake-devel aclocal autoconf autotools cmake make
RUN yum -y install g++ gcc gcc-c++ gcc-gfortran
RUN yum -y install blas-devel boost-devel fftw3-devel fftw3-libs python-devel lapack-devel libpng-devel libxml2-devel numpy-devel readline-devel ncurses-devel f2py bzip2-devel libicu-devel scipy python-setuptools libgsl-devel 
RUN yum -y install bison flex ncurses tar bzip2 which gettext 
RUN echo "start install hdf5-devel"
RUN yum -y install epel-release
RUN yum-config-manager --enable epel
RUN yum -y install hdf5-devel
RUN echo "end install hdf5-devel"
RUN wget --retry-connrefused https://bootstrap.pypa.io/get-pip.py -O - | python
RUN pip install pyfits pywcs python-monetdb xmlrunner unittest2
#RUN pip install astropy --no-deps
RUN pip install astropy==1.3.3

#
# install-cfitsio
#
RUN mkdir -p ${INSTALLDIR}/cfitsio/build
RUN cd ${INSTALLDIR}/cfitsio && wget --retry-connrefused ftp://anonymous@heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio${CFITSIO_VERSION}.tar.gz
RUN cd ${INSTALLDIR}/cfitsio && tar xf cfitsio${CFITSIO_VERSION}.tar.gz
RUN cd ${INSTALLDIR}/cfitsio/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/cfitsio/ ../cfitsio
RUN cd ${INSTALLDIR}/cfitsio/build && make -j ${J}
RUN cd ${INSTALLDIR}/cfitsio/build && make install

#
# install-wcslib
#
RUN mkdir ${INSTALLDIR}/wcslib
RUN if [ "${WCSLIB_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib.tar.bz2 -O wcslib-latest.tar.bz2; fi
RUN if [ "${WCSLIB_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/wcslib && wget --retry-connrefused ftp://anonymous@ftp.atnf.csiro.au/pub/software/wcslib/wcslib-${WCSLIB_VERSION}.tar.bz2; fi
RUN cd ${INSTALLDIR}/wcslib && tar xf wcslib-*.tar.bz2
RUN cd ${INSTALLDIR}/wcslib/wcslib* && ./configure --prefix=${INSTALLDIR}/wcslib --with-cfitsiolib=${INSTALLDIR}/cfitsio/lib/ --with-cfitsioinc=${INSTALLDIR}/cfitsio/include/ --without-pgplot
RUN cd ${INSTALLDIR}/wcslib/wcslib* && make
RUN cd ${INSTALLDIR}/wcslib/wcslib* && make install

#
# install-hdf5
#

#RUN mkdir -p ${INSTALLDIR}/hdf5
#RUN cd ${INSTALLDIR}/hdf5 && wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz
#RUN cd ${INSTALLDIR}/hdf5 && tar xf hdf5*.tar.gz
#RUN cd ${INSTALLDIR}/hdf5/hdf5*/ && ./configure --prefix=${INSTALLDIR}/hdf5 --enable-fortran --enable-threadsafe --enable-cxx --with-pthread --enable-linux-lfs --enable-unsupported
#RUN cd ${INSTALLDIR}/hdf5/hdf5*/ && make -j ${J}
#RUN cd ${INSTALLDIR}/hdf5/hdf5*/ && make install

#
# install-casacore
#
RUN mkdir -p ${INSTALLDIR}/casacore/build
RUN mkdir -p ${INSTALLDIR}/casacore/data
RUN cd ${INSTALLDIR}/casacore && git clone https://github.com/casacore/casacore.git src
RUN if [ "${CASACORE_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casacore/src && git checkout tags/${CASACORE_VERSION}; fi
RUN cd ${INSTALLDIR}/casacore/data && wget --retry-connrefused ftp://anonymous@ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar
RUN cd ${INSTALLDIR}/casacore/data && tar xf WSRT_Measures.ztar
#RUN cd ${INSTALLDIR}/casacore/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DDATA_DIR=${INSTALLDIR}/casacore/data -DWCSLIB_ROOT_DIR=/${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DHDF5_ROOT_DIR=${INSTALLDIR}/hdf5 -DUSE_HDF5=True ../src/ 
RUN cd ${INSTALLDIR}/casacore/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DDATA_DIR=${INSTALLDIR}/casacore/data -DWCSLIB_ROOT_DIR=/${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DBUILD_PYTHON=True -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True ../src/ 
RUN cd ${INSTALLDIR}/casacore/build && make -j ${J}
RUN cd ${INSTALLDIR}/casacore/build && make install

#
# install-casarest
#
#RUN mkdir -p ${INSTALLDIR}/casarest/build
#RUN cd ${INSTALLDIR}/casarest && git clone https://github.com/casacore/casarest.git src
#RUN if [ "${CASAREST_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/casarest/src && git checkout tags/${CASAREST_VERSION}; fi
#RUN cd ${INSTALLDIR}/casarest/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casarest -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio -DHDF5_ROOT_DIR=${INSTALLDIR}/hdf5 -DHDF5_INCLUDE_DIR=${INSTALLDIR}/hdf5/include -DHDF5_LIBRARY=${INSTALLDIR}/hdf5/lib ../src/
#RUN cd ${INSTALLDIR}/casarest/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casarest -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio ../src/
#RUN cd ${INSTALLDIR}/casarest/build && make -j ${J}
#RUN cd ${INSTALLDIR}/casarest/build && make install

#
# install-python-casacore
#
RUN mkdir ${INSTALLDIR}/python-casacore
RUN cd ${INSTALLDIR}/python-casacore && git clone https://github.com/casacore/python-casacore
RUN if [ "$PYTHON_CASACORE_VERSION" != "latest" ]; then cd ${INSTALLDIR}/python-casacore/python-casacore && git checkout tags/${PYTHON_CASACORE_VERSION}; fi
RUN cd ${INSTALLDIR}/python-casacore/python-casacore && ./setup.py build_ext -I${INSTALLDIR}/wcslib/include:${INSTALLDIR}/casacore/include/:${INSTALLDIR}/cfitsio/include -L${INSTALLDIR}/wcslib/lib:${INSTALLDIR}/casacore/lib/:${INSTALLDIR}/cfitsio/lib/ -R${INSTALLDIR}/wcslib/lib:${INSTALLDIR}/casacore/lib/:${INSTALLDIR}/cfitsio/lib/
RUN mkdir -p ${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages/
RUN mkdir -p ${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages/
RUN export PYTHONPATH=${INSTALLDIR}/python-casacore/lib/python${PYTHON_VERSION}/site-packages:${INSTALLDIR}/python-casacore/lib64/python${PYTHON_VERSION}/site-packages:$PYTHONPATH && cd ${INSTALLDIR}/python-casacore/python-casacore && ./setup.py develop --prefix=${INSTALLDIR}/python-casacore/

#
# install-log4cplus
#
#RUN mkdir -p ${INSTALLDIR}/log4cplus/build
#RUN cd ${INSTALLDIR}/log4cplus && git clone https://github.com/log4cplus/log4cplus.git -b ${LOG4CPLUS_VERSION} src
#RUN cd ${INSTALLDIR}/log4cplus/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/log4cplus ../src/
#RUN cd ${INSTALLDIR}/log4cplus/build && make -j ${J}
#RUN cd ${INSTALLDIR}/log4cplus/build && make install



#
# LOFEX
#

#
# install-aoflagger
#
RUN mkdir -p ${INSTALLDIR}/aoflagger/build
RUN cd ${INSTALLDIR}/aoflagger && git clone git://git.code.sf.net/p/aoflagger/code aoflagger
RUN cd ${INSTALLDIR}/aoflagger/aoflagger && git checkout tags/${AOFLAGGER_VERSION}
RUN cd ${INSTALLDIR}/aoflagger/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio -DBUILD_SHARED_LIBS=ON ../aoflagger
RUN cd ${INSTALLDIR}/aoflagger/build && make -j ${J}
RUN cd ${INSTALLDIR}/aoflagger/build && make install

#
# install-pybdsf
#
RUN mkdir -p ${INSTALLDIR}/pybdsf
RUN cd ${INSTALLDIR}/pybdsf && git clone https://github.com/lofar-astron/pybdsf pybdsf 
RUN cd ${INSTALLDIR}/pybdsf/pybdsf && git checkout tags/${PYBDSF_VERSION} && mkdir -p ${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ && mkdir -p ${INSTALLDIR}/pybdsf/lib64/python${PYTHON_VERSION}/site-packages/ && export PYTHONPATH=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages:${INSTALLDIR}/pybdsf/lib64/python${PYTHON_VERSION}/site-packages:$PYTHONPATH && cd ${INSTALLDIR}/pybdsf/pybdsf && python setup.py install --prefix=${INSTALLDIR}/pybdsf/

#
# install-LSMTool
#
RUN mkdir -p ${INSTALLDIR}/LSMTool && \
    cd ${INSTALLDIR}/LSMTool && git clone https://github.com/darafferty/LSMTool.git && \
    cd ${INSTALLDIR}/LSMTool/LSMTool && git checkout ${LSMTOOL_VERSION} && \
    mkdir -p ${INSTALLDIR}/LSMTool/lib/python${PYTHON_VERSION}/site-packages/ && \
    export PYTHONPATH=${PYTHONPATH}:${INSTALLDIR}/LSMTool/lib/python${PYTHON_VERSION}/site-packages/ && \
    python setup.py install --prefix=${INSTALLDIR}/LSMTool # && \
    # bash -c "find ${INSTALLDIR}/LSMTool/lib -name '*.so' | xargs strip || true" && \
    # bash -c "rm -rf ${INSTALLDIR}/LSMTool/LSMTool"

#
# install-lofar
#
RUN mkdir -p ${INSTALLDIR}/lofar
RUN mkdir -p ${INSTALLDIR}/lofar/build
RUN mkdir -p ${INSTALLDIR}/lofar/build/gnu_opt
RUN ls ${INSTALLDIR}
RUN ls ${INSTALLDIR}/lofar
RUN ls ${INSTALLDIR}/lofar/build/gnu_opt
RUN if [ "${LOFAR_VERSION}" = "latest" ]; then cd ${INSTALLDIR}/lofar && svn --non-interactive -q co https://svn.astron.nl/LOFAR/trunk src; fi
RUN if [ "${LOFAR_VERSION}" != "latest" ]; then cd ${INSTALLDIR}/lofar && svn --non-interactive -q co https://svn.astron.nl/LOFAR/tags/LOFAR-Release-${LOFAR_VERSION} src; fi
#RUN cd ${INSTALLDIR}/lofar/build/gnu_opt && cmake -DBUILD_PACKAGES=Offline -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/  -DCASAREST_ROOT_DIR=${INSTALLDIR}/casarest/ -DAOFLAGGER_ROOT_DIR=${INSTALLDIR}/aoflagger/ -DLOG4CPLUS_ROOT_DIR=${INSTALLDIR}/log4cplus/ -DBDSF_ROOT_DIR=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ -DUSE_OPENMP=True ${INSTALLDIR}/lofar/src/
RUN cd ${INSTALLDIR}/lofar/build/gnucxx11_opt && cmake -DBUILD_PACKAGES="DPPP DP3 StationResponse BBSControl" -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/lofar/ -DWCSLIB_ROOT_DIR=${INSTALLDIR}/wcslib/ -DCFITSIO_ROOT_DIR=${INSTALLDIR}/cfitsio/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore/  -DCASAREST_ROOT_DIR=${INSTALLDIR}/casarest/ -DAOFLAGGER_ROOT_DIR=${INSTALLDIR}/aoflagger/ -DUSE_LOG4CPLUS=OFF -DBDSF_ROOT_DIR=${INSTALLDIR}/pybdsf/lib/python${PYTHON_VERSION}/site-packages/ -DUSE_OPENMP=True ${INSTALLDIR}/lofar/src/
RUN cd ${INSTALLDIR}/lofar/build/gnu_opt && make install

#
# init-lofar
#
RUN sudo sh -c 'echo source \${INSTALLDIR}/lofar/lofarinit.sh  >> /usr/bin/init-lofar.sh'
RUN sudo sh -c 'echo export PYTHONPATH=\${PYTHONPATH:+:\${PYTHONPATH}}:\${INSTALLDIR}/python-casacore/lib/python2.7/site-packages/  >> /usr/bin/init-lofar.sh'
RUN sudo sh -c 'echo export PATH=\${PATH:+:\$PATH}:\${INSTALLDIR}/casacore/bin  >> /usr/bin/init-lofar.sh'
RUN sudo sh -c 'echo export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}:\${INSTALLDIR}/casacore/lib  >> /usr/bin/init-lofar.sh'
RUN sudo sh -c "echo source /usr/bin/init-lofar.sh >> /usr/bin/init.sh"


#
# ADDING EXTENSIONS
#

#
# base
#
RUN yum -y remove iputils
RUN yum -y update
RUN yum -y install sudo
RUN yum -y install git svn wget 
RUN yum -y install automake-devel aclocal autoconf autotools cmake make
RUN yum -y install g++ gcc gcc-c++ gcc-gfortran
RUN yum -y install blas-devel boost-devel fftw3-devel fftw3-libs python-devel lapack-devel libpng-devel libxml2-devel numpy-devel readline-devel ncurses-devel f2py bzip2-devel libicu-devel scipy python-setuptools libgsl-devel
RUN yum -y install bison flex ncurses tar bzip2 which gettext

RUN yum -y install gsl-devel
RUN yum -y install numpy
RUN yum -y install python-matplotlib

RUN wget --retry-connrefused https://bootstrap.pypa.io/get-pip.py -O - | python
RUN pip install pyfits pywcs python-monetdb xmlrunner unittest2 ipython

RUN cd ${INSTALLDIR}
RUN ls ${INSTALLDIR}

#
# install-WSClean
#
RUN export CPATH=${INSTALLDIR}/casacore/include:$CPATH
RUN mkdir ${INSTALLDIR}/wsclean
RUN cd ${INSTALLDIR}/wsclean && wget http://downloads.sourceforge.net/project/wsclean/wsclean-${WSCLEAN_VERSION}/wsclean-${WSCLEAN_VERSION}.tar.bz2 && tar -xjf wsclean-${WSCLEAN_VERSION}.tar.bz2 && cd wsclean-${WSCLEAN_VERSION} && ls && mkdir build && cd build && ls && cmake .. -DCMAKE_PREFIX_PATH="${INSTALLDIR}/casacore;${INSTALLDIR}/cfitsio;${INSTALLDIR}/lofar" && make -j ${J}
RUN ls ${INSTALLDIR}

#
# install-Dysco
#
RUN mkdir ${INSTALLDIR}/dysco 
RUN cd ${INSTALLDIR}/dysco && git clone https://github.com/aroffringa/dysco.git && cd ${INSTALLDIR}/dysco/dysco && git checkout tags/${DYSCO_VERSION} && ls && mkdir build && cd build && ls && cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/dysco -DCMAKE_PREFIX_PATH="${INSTALLDIR}/casacore;${INSTALLDIR}/cfitsio;${INSTALLDIR}/lofar" && make -j ${J} && make install
RUN ls ${INSTALLDIR}


#
# install-RMextract
#
ENV PYTHONPATH /opt/lofar/RMextract/lib64/python2.7/site-packages
RUN echo ${PYTHONPATH}
RUN mkdir ${INSTALLDIR}/RMextract
RUN mkdir ${INSTALLDIR}/RMextract/build
RUN mkdir ${INSTALLDIR}/RMextract/lib64
RUN mkdir ${INSTALLDIR}/RMextract/lib64/python2.7
RUN mkdir ${INSTALLDIR}/RMextract/lib64/python2.7/site-packages
RUN cd ${INSTALLDIR}/RMextract/build && git clone https://github.com/lofar-astron/RMextract.git src && cd src && git checkout tags/${RMEXTRACT_VERSION} && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/RMextract
RUN ls ${INSTALLDIR}

#
# install-Losoto
#
ENV PYTHONPATH /opt/lofar/losoto/lib/python2.7/site-packages/
RUN mkdir ${INSTALLDIR}/losoto
RUN mkdir ${INSTALLDIR}/losoto/build
RUN mkdir ${INSTALLDIR}/losoto/lib
RUN mkdir ${INSTALLDIR}/losoto/lib/python2.7
RUN mkdir ${INSTALLDIR}/losoto/lib/python2.7/site-packages
RUN cd ${INSTALLDIR}/losoto/build && git clone https://github.com/revoltek/losoto.git src && cd src && git checkout tags/${LOSOTO_VERSION} && python setup.py build && python setup.py install --prefix=${INSTALLDIR}/losoto

# list installdir contents
RUN ls ${INSTALLDIR}

RUN rm -rf ${INSTALLDIR}/lofar/src
RUN rm -rf ${INSTALLDIR}/lofar/build/gnu_opt
RUN rm -rf ${INSTALLDIR}/casacore/src
RUN rm -rf ${INSTALLDIR}/casarest/src

RUN yum -y clean all

RUN ls ${INSTALLDIR}

#
# entrypoint
#
ENTRYPOINT /bin/bash --init-file /usr/bin/init.sh


