cd $INSTALLDIR
wget https://archives.boost.io/release/1.89.0/source/boost_1_89_0.tar.gz
tar -xzf boost_1_89_0.tar.gz
cd boost_1_89_0

# Build Boost with Python 3.12
./bootstrap.sh --with-libraries=python
# https://www.boost.org/doc/libs/1_89_0/tools/build/doc/html/index.html
sudo ./b2 -j $J --without-test python=3.12 threading=multi cflags="`python3.12-config --cflags`" cxxflags="`python3.12-config --includes`" linkflags="`python3.12-config --libs`" install
cd $INSTALLDIR
rm -rf boost_1_89_0.tar.gz boost_1_89_0
