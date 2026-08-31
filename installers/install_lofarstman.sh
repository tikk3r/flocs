mkdir -p $INSTALLDIR/lofarstman
cd $INSTALLDIR/lofarstman
git clone https://github.com/lofar-astron/LofarStMan.git
cd LofarStMan
mkdir build && cd build
cmake $CMAKE_ADD_OPTION -DCASACORE_ROOT_DIR=$INSTALLDIR/casacore -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/lofarstman ..
make -j$J
make install
cd $INSTALLDIR
rm -rf $INSTALLDIR/lofarstman/LofarStMan
