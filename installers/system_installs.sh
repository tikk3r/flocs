dnf -y update
dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install wget
wget https://raw.githubusercontent.com/tikk3r/flocs/fedora-py3/dnf-packages.txt -O $INSTALLDIR/dnf-packages.txt
dnf -y install $(<$INSTALLDIR/dnf-packages.txt)

wget --progress=bar:force:noscroll https://download.oracle.com/otn_software/linux/instantclient/2360000/oracle-instantclient-basic-23.6.0.24.10-1.el9.x86_64.rpm
dnf -y install oracle-instantclient-basic-23.6.0.24.10-1.el9.x86_64.rpm
rm oracle-instantclient-basic-*.rpm

if [ $DEBUG = true ]; then
    dnf -y install gdb valgrind mc
    debuginfo-install -y libstdc++
fi
