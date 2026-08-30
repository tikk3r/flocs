mkdir /opt/aocl
cd /opt/aocl
wget --progress=bar:force:noscroll  https://download.amd.com/developer/eula/aocl/aocl-5-1/aocl-linux-aocc-5.1.0.tar.gz
tar xf aocl-linux-aocc-5.1.0.tar.gz
rm aocl-linux-*.tar.gz
cd aocl-linux-aocc-5.1.0
./install.sh -t /opt/aocl -i lp64
source /opt/aocl/5.1.0/aocc/amd-libs.cfg
export CPATH=/opt/aocl/5.1.0/aocc/include:$CPATH
# Added with Fedora 42 update, otherwise EveryBeam crashes on import.
find /opt/aocl/5.1.0/aocc/ -name "libamdlibm*.so" -exec execstack -c {} \;

# Get libflang.so, libpgmath.so
mkdir -p /opt/flang
cd /opt/flang
wget --progress=bar:force:noscroll https://github.com/flang-compiler/flang/releases/download/flang_20190329/flang-20190329-x86-70.tgz
tar xf flang-20190329-x86-70.tgz
rm flang-*.tgz

# Explicitely reinstall FFTW since it wasn't built with threads.
rm -rf $AOCL_ROOT/amd-fftw $AOCL_ROOT/lib/libfftw*.so $AOCL_ROOT/include/fftw3*
mkdir -p /opt/fftw/
cd /opt/fftw/
git clone https://github.com/amd/amd-fftw.git
cd amd-fftw
# Install single precision version
./configure --enable-float --enable-threads --enable-sse2 --enable-avx --enable-avx2 --enable-avx512 --enable-mpi --enable-openmp --enable-shared --enable-amd-opt --enable-amd-mpifft --prefix=$AOCL_ROOT
make -j $J
make install
# Install double precision version
make clean
./configure --enable-threads --enable-sse2 --enable-avx --enable-avx2 --enable-avx512 --enable-mpi --enable-openmp --enable-shared --enable-amd-opt --enable-amd-mpifft --prefix=$AOCL_ROOT
make -j $J
make install
cd $INSTALLDIR
rm -rf /opt/fftw
rm -rf /opt/aocl/aocl-linux-aocc-5.1.0
ls /opt/aocl/5.1.0/aocc/lib/

export LD_LIBRARY_PATH=/opt/flang/lib:$LD_LIBRARY_PATH
export PATH=/opt/flang/bin:$PATH
export CPATH=/opt/flang/include:$CPATH
export CPLUS_INCLUDE_PATH=/opt/flang/include:$CPLUS_INCLUDE_PATH
