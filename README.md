# lofar-grid-hpccloud
Visit the  [wiki](https://github.com/tikk3r/lofar-grid-hpccloud/wiki) for more detailed information.
----------------------------------------
This repository hold resources for deploying the LOFAR software and related tools through Singularity images.
 
 
Other software related notes
----------------------------
- LOFAR software ignores compilers and resorts just to /usr/bin/gcc and /usr/bin/g++. This is fixed with `lofar.patch`.
- AOFlagger needs to use the old `_GLIB_CXX_USE_ABI=0`, this is fixed in `aoflagger.patch`.
- Python CASAcore `setup.py` is broken with regards to finding libraries passed along by the -L flag. This is fixed with the patch.
- Apparently WCSLIB now needs a newer version of GNU Make. It no longer worked with 3.82, tested to work with 4.2.
- Latest log4cplus (no longer installed) requires CMake 3.6:

    yum install -y cmake3
    
- Installing log4cplus requires `--recursive` when cloning, otherwise the `catch.hpp` and `threadpool.h` headers are not found.

    
