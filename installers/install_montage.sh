cd $INSTALLDIR
mkdir montage
cd montage
wget --progress=bar:force:noscroll https://github.com/Caltech-IPAC/Montage/archive/v6.0.tar.gz -O Montage_v6.0.tar.gz
tar xf Montage_v6.0.tar.gz
cd Montage-6.0
make -j $J
rm -rf $INSTALLDIR/montage/Montage_v6.0.tar.gz
