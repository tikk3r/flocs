[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/1999)
<img src="https://img.shields.io/github/release/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>

# lofar-grid-hpccloud

This repository hold resources for deploying the LOFAR software and related tools through a native install, Singularity images or for use on the HPC Cloud, or other systems.

To build a full LOFAR Singularity image, do the following:
1) Build Singularity.lofarbase
2) Build Singularity.lofar
3) Build Singularity.lofarddf (optional)

`lofarbase` and `lofar` are available on Singularity-hub, and can be downloaded with

    singularity pull --name customname.simg shub://tikk3r/lofar-grid-hpccloud:<image>[@<specific has>]

The hash is optional. By default the latest version is downloaded. An example command is `singularity pull --name lofar.simg shub://tikk3r/lofar-grid-hpccloud:lofar`.

Visit the  [wiki](https://github.com/tikk3r/lofar-grid-hpccloud/wiki) for more detailed information and build instructions.
 
Other software related notes
----------------------------
- LOFAR software ignores compilers and resorts just to /usr/bin/gcc and /usr/bin/g++. This is fixed with `lofar.patch`.
- Python CASAcore `setup.py` is broken with regards to finding libraries passed along by the -L flag. This is fixed with the patch.
- Apparently WCSLIB now needs a newer version of GNU Make. It no longer worked with 3.82, tested to work with 4.2.
- Latest log4cplus (no longer installed) requires CMake 3.6:

    yum install -y cmake3
    
- Installing log4cplus requires `--recursive` when cloning, otherwise the `catch.hpp` and `threadpool.h` headers are not found.

    
