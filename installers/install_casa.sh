dnf -y install fuse fuse-libs git-lfs

mkdir -p /opt/casa
cd /opt/casa
wget https://casa.nrao.edu/download/distro/casa/release/rhel/casa-6.7.0-31-py3.12.el8.tar.xz
unxz casa-6.7.0-31-py3.12.el8.tar.xz
tar xf casa-6.7.0-31-py3.12.el8.tar
rm -f casa-6.7.0-31-py3.12.el8.tar
echo export PATH=/opt/casa/casa-6.7.0-31-py3.12.el8/bin/:\$PATH  >> $INSTALLDIR/init.sh

pip install casaconfig==1.3.1
pip install casatasks==6.7.0.31
pip install casatestutils==6.7.0.31
pip install casadata==2025.3.17
