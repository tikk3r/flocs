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
sudo yum install -y build-essential libtool autotools-devel automake autoconf libarchive-devel
# Install Singularity.
git clone https://github.com/singularityware/singularity.git
cd singularity
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install
