---
title: Release Notes
layout: default
nav_order: 5
---

# Release notes
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## v4.3.0
**Updates**
* Add [RM-Tools](https://github.com/CIRADA-Tools/RM-Tools)
* Add [shadeMS](https://github.com/ratt-ru/shadeMS)
* Update AOCL to version 4
* Update `create_mslist.py` to include all LINC settings.
* Update DP3 to 161559ff
* Update EveryBeam to 22cd113b
* Update OpenBLAS to v0.3.22
* Update WSClean to 1c1c1d73

## v4.2.2
**Fixes**
* Downgrade IPython to 8.10.

## v4.2.1
**Updates**
* Deprecate `generic` container in favour of `sandybridge` container since AMD now has a specific container and 12 year old hardware seems a reasonable bottom line.

**Fixes**
* Fix LD_LIBRARY_PATH for Intel oneAPI MKL.


## v4.2.0
**Updates**
* Actually update Intel MKL 2020 to Intel oneAPI MKL 2023.
* Add `rclone`.
* Add `swarp`.
* Freeze IDG to `f4a3a96c`.
* Update WSClean to `test-dd-psf-with-faceting` to support feathering and direction-dependent psfs.

**Fixes**
* Fix for threading in DP3's constrained solves.
* Closes #57 
* Closes #58 


## v4.1.0
**Major changes**
- Container base updated to Fedora 36
- Separate recipe for AMD builds using the AMD Optimizing CPU Libraries (AOCL) added.

**Updates**
* Add [EveryStamp](https://github.com/tikk3r/EveryStamp) Python package.
* Add [SAGEcal](https://github.com/nlesc-dirac/sagecal)'s libdirac for the LBFGS solver (used in e.g LINC's demixing).
* Add swarp.
* Freeze ddf-pipeline to 37070a9
* Update DP3 to 5dab4c43
* Include debugging tools `gdb`, `valgrind` and `perf` controlled by the `DEBUG` environment variable.
* Include debug symbols if `DEBUG` is true.
* Update DS9 to 8.5b1.
* Update EveryBeam to 6c7c1fed.
* Update HDF5 to 1.12.1.
* Update Intel MKL to Intel oneAPI MKL.
* Update OpenBLAS to v0.3.22.
* Update WSClean to 65172baf.

**Changes**
* Build IDG in Release mode instead of Debug.
* Build NumPy manually to link against custom OpenBLAS.
* Build OpenBLAS manually for 128 threads to resolve OpenBLAS threading warnings and crashes.