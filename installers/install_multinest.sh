cd $INSTALLDIR
mkdir MultiNest
git clone https://github.com/JohannesBuchner/MultiNest MultiNest-src
cd MultiNest-src/build
cmake $CMAKE_ADD_OPTION -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/MultiNest -DBLA_VENDOR=$BLA_VENDOR ..
make install
cd $INSTALLDIR
rm -rf MultiNest-src
