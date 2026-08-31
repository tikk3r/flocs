mkdir -p $INSTALLDIR/difmap
cd $INSTALLDIR/difmap
#wget --progress=bar:force:noscroll ftp://ftp.astro.caltech.edu/pub/difmap/difmap2.5e.tar.gz
wget --progress=bar:force:noscroll https://github.com/tikk3r/flocs/blob/master/misc/difmap2.5e.tar.gz?raw=true -O difmap2.5e.tar.gz
tar xf difmap2.5e.tar.gz
cd uvf_difmap
wget --progress=bar:force:noscroll https://raw.githubusercontent.com/nealjackson/loop3_difmap/master/corplt.c -O difmap_src/corplt.c

sed -i.bak -e '97d' configure
sed -i.bak -e '97 i PGPLOT_LIB=/usr/lib64/libpgplot.so.5' configure
./configure linux-i486-gcc
export PGPLOT_LIB=/usr/lib64/libpgplot.so.5
export OLD_CFLAGS=$CFLAGS
export CFLAGS="-L/usr/lib64/libpgplot.so.5"
CC=`which gcc` ./makeall
rm -rf $INSTALLDIR/difmap/*.tar.gz
export CFLAGS=$OLD_CFLAGS
