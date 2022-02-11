FROM fedora:34
ARG MARCH=x86-64
ARG MTUNE=generic
ARG NOAVX512

# General environment settings.
ENV J=6 
ENV INSTALLDIR=/opt/lofar
ENV PYTHON_VERSION=3.10.1
ENV OPENBLAS_NUM_THREADS=1

# Path to where the patch for python-casacore's setup is stored.
ENV PYTHON_CASACORE_PATCH=$INSTALLDIR/python-casacore/python_casacore_setup_patch.patch

# Settings relevant to the installed software.
#ENV AOFLAGGER_VERSION=v3.1.0
ENV AOFLAGGER_VERSION=master
ENV ARMADILLO_VERSION=9.900.3
ENV BLAS_VERSION=3.8.0
ENV BOOST_DOT_VERSION=1.69.0
ENV BOOST_VERSION=1.69.0
ENV CASACORE_VERSION=v3.4.0
# Leave at latest, release versions crash for some reason.
ENV CASAREST_VERSION=latest
ENV CFITSIO_VERSION=7.3.47
#ENV DPPP_VERSION=e5eff2e
ENV DPPP_VERSION=master
ENV DYSCO_VERSION=v1.2
#ENV EVERYBEAM_VERSION=v0.1.3
#ENV EVERYBEAM_VERSION=0c26c65d
ENV EVERYBEAM_VERSION=master
ENV FFTW_VERSION=3.5.8
ENV HDF5_VERSION=1.10.5
#ENV IDG_VERSION=master
ENV IDG_VERSION=03b30672
ENV LAPACK_VERSION=3.8.0
ENV LOSOTO3_VERSION=latest
ENV LSMTOOL_VERSION=v1.4.2
ENV OPENBLAS_VERSION=3.8.0
ENV PYBDSF_VERSION=master
ENV PYTHON_CASACORE_VERSION=v3.4.0
ENV RMEXTRACT_VERSION=4c61232
ENV SUPERLU_VERSION=5.2.1
#ENV WSCLEAN_VERSION=c0a654ca
ENV WSCLEAN_VERSION=master
ENV WCSLIB_VERSION=6.4
ENV HDF5_USE_FILE_LOCKING=FALSE
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

ENV MARCH=$MARCH
ENV MTUNE=$MTUNE
ENV WITH_MKL=$WITH_MKL
ENV WITH_CUDA=$WITH_CUDA

ENV NCPU="\$(nproc --all)"
ENV OPENBLAS_NUM_THREADS=1
ENV OPENBLAS_MAX_THREADS=\$NCPU
ENV OMP_NUM_THREADS=\$NCPU
ENV OMP_MAX_THREADS=\$NCPU

# Some Bash voodoo to get conditional stuff into Docker
# https://wiki.bash-hackers.org/syntax/pe
# https://stackoverflow.com/questions/37057468/conditional-env-in-dockerfile
ENV CFLAGS="-march=${MARCH} -mtune=${MTUNE} "${NOAVX512:+"-mno-avx512f -mno-avx512pf -mno-avx512er -mno-avx512cd -mno-avx512vl -mno-avx512bw -mno-avx512dq -mno-avx512ifma -mno-avx512vbmi"}
ENV CXXFLAGS="-march=${MARCH} -mtune=${MTUNE} -std=c++14 "${NOAVX512:+"-mno-avx512f -mno-avx512pf -mno-avx512er -mno-avx512cd -mno-avx512vl -mno-avx512bw -mno-avx512dq -mno-avx512ifma -mno-avx512vbmi"}

#
# Environment for future compile steps.
#
ENV CPLUS_INCLUDE_PATH="/opt/hdf5/include:/usr/include/openmpi-x86_64:/usr/include/c++/9:$CPLUS_INCLUDE_PATH:$INSTALLDIR/casacore/include:/usr/include/boost:/usr/include/cfitsio:$INSTALLDIR/EveryBeam/include:$INSTALLDIR/idg/include"
ENV CPATH="/usr/include/openmpi-x86_64/:/usr/local/cuda/include:/opt/hdf5/include:/opt/intel/mkl/include:${INSTALLDIR}/casacore/include:$INSTALLDIR/idg/include:$INSTALLDIR/aoflagger/include:$INSTALLDIR/EveryBeam/include:$INSTALLDIR/idg/include:$CPATH"
ENV CMAKE_PREFIX_PATH="$INSTALLDIR/aoflagger:$INSTALLDIR/casacore:/opt/hdf5:$INSTALLDIR/lofar:/usr/local/cuda/lib64:/opt/intel/mkl/lib/intel64:/usr/lib64/openmpi:$INSTALLDIR/EveryBeam:$INSTALLDIR/idg"
ENV LD_LIBRARY_PATH="$INSTALLDIR/aoflagger/lib:$INSTALLDIR/casacore/lib:$INSTALLDIR/DPPP/lib:$INSTALLDIR/dysco/lib:/opt/hdf5/lib:$INSTALLDIR/idg/lib:/usr/local/cuda/lib64:/opt/intel/mkl/lib/intel64:/usr/lib64/openmpi/lib/:$INSTALLDIR/EveryBeam/lib:$LD_LIBRARY_PATH"
ENV PATH="/usr/local/cuda/bin:/opt/hdf5/bin:\$INSTALLDIR/aoflagger/bin:\$INSTALLDIR/casacore/bin:\$INSTALLDIR/ds9/bin:\$INSTALLDIR/DPPP/bin:\$INSTALLDIR/difmap/uvf_difmap:\$INSTALLDIR/dysco/bin:/opt/hdf5/bin:\$INSTALLDIR/wsclean/bin:/usr/lib64/openmpi/bin:$PATH"

#
# Install general dependencies.
#
RUN dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm &&\
 dnf -y update &&\
 dnf -y install dnf-plugins-core\
 patch sudo yum-utils hostname\
 git svn wget vim nano\
 automake autoconf cmake make\
 gcc gcc-c++ gcc-gfortran\
 arpack-devel python-devel python3-devel lapack-devel libpng-devel libxml2-devel readline-devel ncurses-devel f2py bzip2-devel libicu-devel python3-scipy python-setuptools gsl gsl-devel gdal gdal-devel libpqxx libpqxx-devel\
 bison flex ncurses tar bzip2 which gettext\
 cmake3\
 python python-devel\
 python-pip python3-tkinter\
 libsigc++20-devel gtkmm30-devel\
 python3-devel\
 lua lua-devel\
 pgplot\
 python3-numpy-f2py\
 qt5-qtbase\
 perf\
 rsync\
 openmpi openmpi-devel\
 htop\
 python3-pybind11 pybind11-devel mysql mysql-devel\
 gdb\
#
# Install more specific dependencies.
#
 boost boost-devel boost-python3 boost-python3-devel\
 fftw-devel fftw-libs\
 blas-devel\
 SuperLU SuperLU-devel\
 armadillo armadillo-devel\
 cfitsio cfitsio-devel\
 wcslib wcslib-devel\
 postgresql-devel libnsl libnsl2-devel

#
# Source installations
#
#
# Install HDF5 with parallel support
#
RUN mkdir /opt/hdf5 &&\
    cd /opt/hdf5 &&\
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz &&\
    tar xf hdf5-${HDF5_VERSION}.tar.gz && cd hdf5-${HDF5_VERSION} &&\
    # Thread safety required for WSClean's parallel gridding with facets.
    ./configure CC=`which mpicc` CXX=`which mpic++` -prefix=/opt/hdf5 --enable-build-mode=production --enable-threadsafe --enable-shared --disable-sharedlib-rpath --disable-hl &&\
    make -j $J && make install

#
# Install Intel MKL if requested
#
ARG WITH_MKL
RUN if [ "$WITH_MKL" = true ]; then sudo dnf config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo && sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && dnf -y install intel-mkl-2020.0-088 intel-mkl-64bit-2020.0-088; fi

#
# Install CUDA if requested
#
ARG WITH_CUDA
RUN if [ "$WITH_CUDA" = true ]; then sudo dnf -y config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/fedora34/x86_64/cuda-fedora34.repo && sudo dnf -y clean all && sudo dnf -y upgrade && sudo dnf -y install cuda-11-5; fi

RUN mkdir -p $INSTALLDIR
#   
# Setup the Python environment.
#   
RUN wget https://raw.githubusercontent.com/tikk3r/lofar-grid-hpccloud/fedora/requirements3.txt -O ${INSTALLDIR}/requirements3.txt &&\
    pip install xmlrunner &&\
    pip --no-cache-dir install virtualenv &&\
    virtualenv $INSTALLDIR/pyenv-py3 --python=python3 &&\
    source $INSTALLDIR/pyenv-py3/bin/activate &&\
    pip install --upgrade pip  &&\
    pip install numpy &&\
    export HDF5_VERSION=1.10.5 &&\
    pip install --no-binary h5py h5py &&\
    pip install -r $INSTALLDIR/requirements3.txt &&\
    pip install lofar-h5plot &&\
    pip install legacystamps

#
# Install difmap
#
RUN mkdir -p $INSTALLDIR/difmap &&\
    cd $INSTALLDIR/difmap &&\
    #wget ftp://ftp.astro.caltech.edu/pub/difmap/difmap2.5e.tar.gz &&\
    wget https://github.com/tikk3r/lofar-grid-hpccloud/blob/master/misc/difmap2.5e.tar.gz?raw=true -O difmap2.5e.tar.gz &&\
    tar xf difmap2.5e.tar.gz &&\
    cd uvf_difmap &&\
    wget https://raw.githubusercontent.com/nealjackson/loop3_difmap/master/corplt.c -O difmap_src/corplt.c &&\
    sed -i.bak -e '97d' configure &&\
    sed -i.bak -e '97 i PGPLOT_LIB=/usr/lib64/libpgplot.so.5' configure &&\
    ./configure linux-i486-gcc &&\
    PGPLOT_LIB=/usr/lib64/libpgplot.so.5 CFLAGS="-L/usr/lib64/libpgplot.so.5" ./makeall &&\
    rm -rf $INSTALLDIR/difmap/*.tar.gz

#
# Install PyBDSF
#
RUN mkdir -p ${INSTALLDIR}/pybdsf &&\
    cd ${INSTALLDIR}/pybdsf && git clone https://github.com/lofar-astron/pybdsf && cd ${INSTALLDIR}/pybdsf/pybdsf && git checkout ${PYBDSF_VERSION} && echo export PYBDSF_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    cd ${INSTALLDIR}/pybdsf/pybdsf &&\
    #python setup.py install &&\
    pip install bdsf &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/pybdsf/pybdsf

#   
# Install CASAcore
#   
RUN mkdir -p ${INSTALLDIR}/casacore/build &&\
    mkdir -p ${INSTALLDIR}/casacore/data &&\
    cd $INSTALLDIR/casacore &&\
    git clone https://github.com/casacore/casacore.git src  &&\
    cd ${INSTALLDIR}/casacore/src && git checkout tags/${CASACORE_VERSION} && echo export CASACORE_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    # Backport patch UVFITS for LOFAR. This is fixed in recent versions > May 26 2020 &&\
    #wget https://patch-diff.githubusercontent.com/raw/casacore/casacore/pull/1033.patch -O $INSTALLDIR/casacore/1033.patch &&\
    #cd $INSTALLDIR/casacore/src && patch --fuzz 3 -p1 < $INSTALLDIR/casacore/1033.patch &&\
    cd ${INSTALLDIR}/casacore/data && wget --retry-connrefused ftp://anonymous@ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar &&\
    cd ${INSTALLDIR}/casacore/data && tar xf WSRT_Measures.ztar && rm WSRT_Measures.ztar &&\
    cd ${INSTALLDIR}/casacore/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/casacore/ -DDATA_DIR=${INSTALLDIR}/casacore/data -DBUILD_PYTHON=False -DUSE_OPENMP=True -DUSE_FFTW3=TRUE -DUSE_HDF5=True -DBUILD_PYTHON3=True ../src/ &&\
    cd ${INSTALLDIR}/casacore/build && make -s -j ${J} &&\
    cd ${INSTALLDIR}/casacore/build && make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/casacore/build &&\
    rm -rf $INSTALLDIR/casacore/src

#   
# Install Python-CASAcore
#   
RUN mkdir -p ${INSTALLDIR}/python-casacore &&\
    cd ${INSTALLDIR}/python-casacore && git clone https://github.com/casacore/python-casacore &&\
    cd ${INSTALLDIR}/python-casacore/python-casacore && git checkout tags/${PYTHON_CASACORE_VERSION} && echo export PYTHON_CASACORE_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    cd ${INSTALLDIR}/python-casacore/python-casacore &&\
    python setup.py build_ext -I${INSTALLDIR}/casacore/include/:/usr/include/python2.7 -L${INSTALLDIR}/casacore/lib/:/usr/lib64/ &&\
    cd $INSTALLDIR/python-casacore/python-casacore &&\
    python setup.py install #--prefix=${INSTALLDIR}/python-casacore/ &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/python-casacore/python-casacore

#
# Install Dysco
#
RUN mkdir -p ${INSTALLDIR}/dysco/build &&\
    cd ${INSTALLDIR}/dysco && git clone https://github.com/aroffringa/dysco.git src &&\
    cd src && git checkout $DYSCO_VERSION && echo export DYSCO_VERSION=$(git rev-parse --short HEAD) >> ${INSTALLDIR}/init.sh &&\
    cd ${INSTALLDIR}/dysco/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/dysco -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DPORTABLE=True ../src && make -s -j $J && make install &&\
    cd ${INSTALLDIR} &&\
    rm -rf ${INSTALLDIR}/dysco/build &&\
    rm -rf ${INSTALLDIR}/dysco/src

#
# Install AOFlagger
#
RUN mkdir -p ${INSTALLDIR}/aoflagger/build &&\
    cd ${INSTALLDIR}/aoflagger && git clone https://gitlab.com/aroffringa/aoflagger.git src && cd ${INSTALLDIR}/aoflagger/src && git checkout ${AOFLAGGER_VERSION} && echo export DYSCO_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    cd ${INSTALLDIR}/aoflagger/build && cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}/aoflagger/ -DCASACORE_ROOT_DIR=${INSTALLDIR}/casacore -DBUILD_SHARED_LIBS=ON -DPORTABLE=True ../src &&\
    cd ${INSTALLDIR}/aoflagger/build && make -s -j ${J} &&\
    cd ${INSTALLDIR}/aoflagger/build && make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/aoflagger/aoflagger &&\
    rm -rf $INSTALLDIR/aoflagger/build &&\
    rm -rf $INSTALLDIR/aoflagger/src

#
# Install LofarStMan
#
RUN mkdir -p $INSTALLDIR/lofarstman &&\
    cd $INSTALLDIR/lofarstman &&\
    git clone https://github.com/lofar-astron/LofarStMan.git &&\
    cd LofarStMan &&\
    mkdir build && cd build &&\
    cmake -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/lofarstman .. &&\
    make -j$J &&\
    make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/lofarstman

#
# Install EveryBeam library
#
RUN mkdir -p $INSTALLDIR/EveryBeam/build &&\
    cd $INSTALLDIR/EveryBeam &&\
    git clone https://git.astron.nl/RD/EveryBeam.git src &&\
    cd src && git checkout $EVERYBEAM_VERSION &&\
    echo export EVERYBEAM_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    cd $INSTALLDIR/EveryBeam/build &&\
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/EveryBeam ../src &&\
    make -j $J &&\
    make install

#   
# Install Image Domain Gridder (IDG)
#   
RUN mkdir -p $INSTALLDIR/idg && cd $INSTALLDIR/idg &&\
    #git clone https://gitlab.com/astron-idg/idg.git src  &&\
    git clone https://git.astron.nl/RD/idg.git src &&\
    cd src && git checkout $IDG_VERSION && echo export IDG_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh && mkdir build && cd build &&\
    cmake3 -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/idg -DBUILD_WITH_MKL=${WITH_MKL:-OFF} -DBUILD_LIB_CUDA=${WITH_CUDA:-OFF} -DCUDA_INCLUDE_DIR=/usr/local/cuda/include -DCMAKE_BUILD_TYPE=Debug .. ;\
    make -j $J &&\
    make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/idg/src

#
# Install DPPP
#
RUN mkdir -p $INSTALLDIR/DPPP/build &&\
    git clone https://git.astron.nl/RD/DP3.git $INSTALLDIR/DPPP/src &&\
    cd $INSTALLDIR/DPPP/src &&\
    git checkout ${DPPP_VERSION} &&\
    echo export DPPP_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    cd $INSTALLDIR/DPPP/build &&\
    # Link to libopenblasp.so (note the p) and not libopenblas.so so we get the multi-threaded version. &&\
    #cmake3 -DCMAKE_CXX_FLAGS="-D_GLIB_USE_CXX_ABI=1 -DBOOST_NO_CXX11_SCOPED_ENUMS" -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLDIR/DPPP -DIDGAPI_LIBRARIES=$INSTALLDIR/idg/lib/libidg-api.so -DIDGAPI_INCLUDE_DIRS=$INSTALLDIR/idg/include -DAOFLAGGER_INCLUDE_DIR=$INSTALLDIR/aoflagger/include -DAOFLAGGER_LIB=$INSTALLDIR/aoflagger/lib/libaoflagger.so -DBLAS_openblas_LIBRARY=/usr/lib64/libopenblasp.so ../src &&\
    cmake3 -DCMAKE_INSTALL_PREFIX:PATH=$INSTALLDIR/DPPP -DIDGAPI_LIBRARIES=$INSTALLDIR/idg/lib/libidg-api.so -DIDGAPI_INCLUDE_DIRS=$INSTALLDIR/idg/include -DAOFLAGGER_INCLUDE_DIR=$INSTALLDIR/aoflagger/include -DAOFLAGGER_LIB=$INSTALLDIR/aoflagger/lib/libaoflagger.so -DBLAS_openblas_LIBRARY=/usr/lib64/libopenblasp.so ../src &&\
    # Boost 1.75 requires c++14, so override this during make &&\
    make CFLAGS="-fPIC -std=c++14" CXX_FLAGS="-fPIC -std=c++14" -s -j $J && make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/DPPP/build &&\
    rm -rf $INSTALLDIR/DPPP/src

#
# Install RMextract
#
RUN mkdir -p $INSTALLDIR/RMextract/build &&\
    cd $INSTALLDIR/RMextract/build &&\
    git clone https://github.com/lofar-astron/RMextract.git src &&\
    cd src &&\
    if [ "$RMEXTRACT_VERSION" != "latest" ]; then git checkout $RMEXTRACT_VERSION; fi &&\
    python setup.py build --add-lofar-utils &&\
    python setup.py install --add-lofar-utils &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/RMextract

#
# Install LoSoTo Py 3
#
RUN mkdir -p $INSTALLDIR/losoto/build &&\
    cd $INSTALLDIR/losoto/build &&\
    git clone https://github.com/revoltek/losoto.git src &&\
    cd src &&\
    python setup.py build &&\
    python setup.py install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/losoto

#
# Install LSMTool.
#
RUN mkdir -p $INSTALLDIR/lsmtool &&\
    cd $INSTALLDIR/lsmtool &&\
    git clone https://github.com/darafferty/LSMTool.git lsmtool &&\
    cd $INSTALLDIR/lsmtool/lsmtool &&\
    if [ "$LSMTOOL_VERSION" != "latest" ]; then git checkout $LSMTOOL_VERSION; fi &&\
    python setup.py install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/lsmtool

#
# Install-WSClean
#
RUN mkdir $INSTALLDIR/wsclean &&\
    cd ${INSTALLDIR}/wsclean && git clone https://gitlab.com/aroffringa/wsclean.git && cd wsclean && git checkout $WSCLEAN_VERSION && echo export WSCLEAN_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh &&\
    mkdir build && cd build &&\
    # TARGET_CPU is a WSClean 2.10.2 feature. Change to PORTABLE=TRUE if using and older version to avoid -march=native being triggered. &&\
    cmake CC=`which mpicc` CXX=`which mpic++` -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/wsclean -DTARGET_CPU=${MARCH} -DIDGAPI_LIBRARIES=$INSTALLDIR/idg/lib/libidg-api.so -DIDGAPI_INCLUDE_DIRS=$INSTALLDIR/idg/include .. &&\
    make CC=`which mpicc` CXX=`which mpic++` -j ${J} &&\
    make install &&\
    cd $INSTALLDIR &&\
    rm -rf $INSTALLDIR/wsclean/wsclean

#
# Install DS9
#
RUN mkdir -p $INSTALLDIR/ds9/bin &&\
    cd $INSTALLDIR/ds9 &&\
    wget https://ds9.si.edu/download/fedora33/ds9.fedora33.8.3.tar.gz &&\
    tar xf ds9*.tar.gz -C $INSTALLDIR/ds9/bin &&\
    rm ds9*.tar.gz

#
# Finaly cleanup of unnecessary stuff
# 
RUN rm -rf /var/cache/dnf/* &&\
    rm -rf /var/cache/yum/* &&\
    rm -rf /var/log/* &&\
    dnf -y clean all &&\
    unset J

RUN ln -s $INSTALLDIR/pyenv-py3/bin/h5plot /usr/bin/h5plot
