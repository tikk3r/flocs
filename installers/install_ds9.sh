mkdir -p $INSTALLDIR/ds9/bin
cd $INSTALLDIR/ds9
wget --progress=bar:force:noscroll https://ds9.si.edu/download/fedora38x86/ds9.fedora38x86.8.7.tar.gz
tar xf ds9*.tar.gz -C $INSTALLDIR/ds9/bin
rm ds9*.tar.gz
