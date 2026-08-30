tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF
sudo mv /tmp/oneAPI.repo /etc/yum.repos.d/
dnf -y install intel-oneapi-mkl intel-oneapi-mkl-devel
# We don't compile with the Intel toolchain
mv /opt/intel/oneapi/compiler/latest/lib/libiomp5.so /opt/intel/oneapi/mkl/latest/lib/
rm -rf /opt/intel/oneapi/compiler
# We don't statically link nor use SYCL
find /opt/intel/oneapi \( -type f -o -type l \) \( -name "*.a" -o -name "libmkl_sycl*" \) -delete
source /opt/intel/oneapi/mkl/latest/env/vars.sh
