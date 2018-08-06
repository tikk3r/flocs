# Install some global packages that are useful.
sudo yum -y install git gcc gcc-c++ vim

# Install Docker.
sudo yum -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
sudo yum-config-manager \
    --add-repo \
   https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce

# Install Singularity dependencies.
sudo yum install -y build-essential libtool autotools-devel automake autoconf libarchive-devel squashfs-tools

# Install Singularity.
git clone https://github.com/singularityware/singularity.git
cd singularity
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install

# Install tools for kvm.
sudo yum install qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer bridge-utils
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
sudo usermod --append --groups libvirt $USER

# Necessary for minimal installation, fixes font related things.
sudo yum -y install "@X Window System" xorg-x11-xauth xorg-x11-fonts-* xorg-x11-utils -y
