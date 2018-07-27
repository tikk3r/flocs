# lofar-grid-hpccloud

1) Install KVM
*) Switch to root
`sudo su -`

In case of "Unable to connect ot libvirt" (caused by user vs. root).
2) Add the user to the libvirt group:
`usermod --append --groups libvirt <user>`

3) Share Template

4) Enable nested VMs
- http://www.rdoxenham.com/?p=275
- Add kernel parameter `kvm-intel.nested=1` (or amd).
- `grub2-mkconfig -o /boot/grub2/grub.cfg`

Set up the nested VM (with graphical interface)
----------------------------------------
1) Add new VM
- Local install media
- Use ISO image
- Allocate memory and CPU
- "Select or create custom storage"
- Manage > Add Volume (blue + sign) > Select name, filesystem and capacity > choose volume
- Check manage before install.
- Make final changes such as architecture etc.
- To enable proper mouse/keyboard passthrough: change the `Graphics type` default to VNC instead of Spice.

Other software
--------------
- PyBDSF can be installed through pip, solves an issue with `PYTHON_BDSF` not being defined.
- Latest log4cplus requires CMake 3.6, which yum does not install by default.

    yum install -y cmake3
    
- Installing log4cplus requires `--recursive` when cloning, otherwise the `catch.hpp` and `threadpool.h` headers are not found.

    
