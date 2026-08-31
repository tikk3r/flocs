sudo dnf -y config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora42/x86_64/cuda-fedora42.repo
sudo dnf -y clean all
sudo dnf -y install cuda-13-0
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
