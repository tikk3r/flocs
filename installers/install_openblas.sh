mkdir -p /opt/OpenBLAS
cd /opt/OpenBLAS
git clone https://github.com/OpenMathLib/OpenBLAS.git src
cd src && git checkout $OPENBLAS_VERSION
mkdir build && cd build
cmake $CMAKE_ADD_OPTION -DCMAKE_INSTALL_PREFIX=/opt/OpenBLAS -DBUILD_TESTING=OFF -DTARGET=$OPENBLAS_TARGET -DUSE_THREAD=1 -DNUM_THREADS=$NUM_THREADS -DNUM_CORES=$NUM_THREADS -DBUILD_SHARED_LIBS=ON -DNO_AVX512=$NOAVX512 ..
make -j$J
make install
rm -rf /opt/OpenBLAS/src
