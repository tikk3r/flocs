echo Installing LOFARBeam...
mkdir -p $INSTALLDIR/LOFARBeam/build
cd $INSTALLDIR/LOFARBeam
git clone https://github.com/lofar-astron/LOFARBeam.git src
cd src
sed -i "s/-std=c++11/-std=${CPPSTD}/" CMakeLists.txt
echo export LOFARBEAM_VERSION=$(git rev-parse --short HEAD) >> $INSTALLDIR/init.sh
cd ../build
# Install in the existing lofar python folder
mkdir -p /opt/lofar/lofar/lib64/python${PYTHON_VERSION}/site-packages/lofar/
touch /opt/lofar/lofar/lib64/python${PYTHON_VERSION}/site-packages/lofar/__init__.py
cmake $CMAKE_ADD_OPTION -DCMAKE_INSTALL_PREFIX=$INSTALLDIR/lofar ../src
make -j $J
make install
cd $INSTALLDIR
rm -rf $INSTALLDIR/LOFARBeam
