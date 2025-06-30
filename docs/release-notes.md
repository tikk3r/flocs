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

## v5.7.0
**Changes**
* Switch to UV for Python management

**Updates**
* Add [Spinifiex](https://git.astron.nl/RD/spinifex)
* Add [astroNNomy](github.com/LOFAR-VLBI/astroNNomy)
* Update AOFlagger to ae522544
* Update casacore to 8e2648a
* Update DP3 to rap-1044-combine-flag-and-data-transfer
* Update EveryBeam to c180e429
* Update IDG to a5675159
* Update WSClean to 8c11e6cb

**Bugfixes**
* Put VLBI-cwl bin path first in VLBI runners

## v5.6.0
**Updates**
* Add `scikit-fuzzy`
* Enable DP3 metadata compression by default.
* Update create_ms_list.py to support LINC full resolution input for delay calibration through `--skip-setup`.
* Update create_ms_list.py to output raw LINC calibrator solutions.
* Update create_ms_list.py to automatically generate LINC's `.versions` file.
* Update casacore -> v3.7.1
* Update DP3 -> c7fe69da
* Update WSClean -> 36818404

## v5.5.1
**Updates**
* Update losoto to e4ed09a
* Update DP3 f475bc30 ->6320b6cf
* Update EveryBeam 59c755a6 -> v0.6.2
* Update WSClean c1e4fcb2 -> df9a4fd2

**Bugfixes**
* Fix default value for `demix_sources` in create_ms_list.py.
* Fix #247 
* Revert 458b1d0, adafefe, e1273c5 and 97da310 due to performance regressions.

## v5.5.0
Updates a number of packages to support new features like the Stokes I model column and various new MS compression aspects that are being or have been developed.

**Updates**
* Add benchmark commands for imaging.
* Build MultiNest with MKL.
* Limit Dask to `<=2024.8.2`
* Switch Dysco installation to casacore.
* Update casacore v3.6.1 -> b027afe
* Update DP3 443bd576 -> a2b1077d
* Update EveryBeam -> 59c755a6
* Update WSClean 443bd576 -> c1e4fcb2/5fdad9bf
* Install lofar_facet_selfcal via pip

**Bug fixes**
* Fix running ddf-pipeline on Slurm
* Fix shadeMS installation

## v5.4.1
**Updates**
* Add ImageMagick.
* Set `BLA_VENDOR` option for AOFlagger, EveryBeam, IDG and WSClean.
* Update ddf-pipeline 72e5285 -> df58808.
* Update PyBDSF 720f5c3 -> 8471637.

**Bug fixes**
* Clean up oneAPI/MKL related environment variables.
* Fix DDFacet and killMS for running ddf-pipeline.

## v5.4.0
Updates base container to Fedora 40:

- Software is now compiled with GCC 14.
- Python version is now 3.12

**Updates**
* Add nctfp for FTP downloads.
* Big cleanup of container recipes (@AlexKurek).
* Increased verbosity in debug builds.
* Update AOFlagger to bdf03b28.
* Update casacore 3.5.0 -> 3.6.1.
* Update `create_ms_list.py` for updated ddf options (@lonbar).
* Update CUDA 12.3 -> 12.6
* Update DDFacet to 5cec4db.
* Update DP3 v6.2 -> 48e75b34.
* Update Dysco  2e7f331 -> 682fe5.
* Update EveryBeam to 65685cba.
* Update HDF5 to 1.14.5
* Update IDG 011687ed -> 2af6f285.
* Update killMS to v3.2.0.
* Update python-casacore 3.5.0 -> 3.6.1.
* Update OpenBLAS v0.3.22 -> v0.3.28.
* Update WSClean v3.5 -> 443bd576.

**Notes**
* MKL temporarily disabled for IDG in favour of upgrading IDG to the latest version.
* Wget is now at version 2, meaning no FTP support anymore. Use `ncftpget` instead.

## v5.3.1
This is the final release with fedora 38, as it is EOL.

**Updates**
* Add `cx_Oracle` Python package.
* Add Oracle Instant Client
* DNF installs common to all both recipes are now (mostly) consolidated into a single file.

**Fixes**
* Fix installation of `sub_sources_outside_region.py`.
* Fix h5py installation.
* Fix LSMTool installation.

## v5.3.0
Python 3.8 reaches end-of-life in October 2024, therefore this release drops support for it.

**Updates**
* Add VLBI-cwl to the container.
* Add `libaio`
* Add [ripgrep](https://github.com/BurntSushi/ripgrep).
* Add `scikit-build`.
* Add `torch`.
* Add option for local flocs directory to runners.
* Drop support for Python 3.8.
* Install `RMextract` from PyPI.
* Update DP3 to v6.2
* Update WSClean to v3.5

**Fixes**
* Fix `h5py` installation (reported by @cristina-star)
* Fix LOFAR LTA client installation (reported by @cristina-star)
* Fix build due to old setuptools (reported by @mat-ole)

## v5.2.0
**Updates**
* Add `Dask[full]` Python package.
* Add `statsmodels` Python package.
* Added LINC and LOFAR-VLBI to the containers (mainly intended as mount points for local versions) to facilitate Toil usage.
* Update DP3 to `930b81f8`
* Update EveryBeam to `df937562`
* Update LOFAR-H5plot to v2.9.1
* Update WSClean to `7efb5092`
* Upgrade HDF5 to 1.14.3

**Fixes**
* Added `-e` option for split directions runner.
* Fixed RFI strategy parameter for LINC JSON generator.

## v5.1.0
**Updates**
* Added [breizorro](https://github.com/ratt-ru/breizorro).
* Added [lofarsun](https://github.com/peijin94/LOFAR-Sun-tools).
* Added [LoSiTo](https://github.com/darafferty/losito).
* Added [SunPy](https://github.com/sunpy/sunpy).
* Added jupyter lab.
* Added [LOFAR LTA client](https://lta.lofar.eu/software/).
* Added [PyMultiNest](https://github.com/JohannesBuchner/PyMultiNest) properly.
* Added support for the subtract workflow in the LOFAR-VLBI pipeline.
* Automatically bind data and runtime directories if a container is used.

**Fixes**
* Fixed boolean parsing in `create_ms_list.py`.
* Fix DDFacet CPU allocation for Slurm.
* Fix ms list creation arguments VLBI delay calibration runner.
* Fix demix argument type for LINC configs.
* Fix spurious apostrophes in some runners.
* Removed unnecessary sed in vlbi runners.

## v5.0.0
Base container updated to Fedora 38

**Updates**
* Add altair and polars Python packages.
* Refactored `create_ms_list.py` to be more flexible (_not_ backwards compatible with older versions).
* Update ddf-pipeline to 72e5285.
* Update DDFacet to v0.7.2.
* Update DP3 to 4df56d1f.
* Update EveryBeam to d52668ec.
* Update LOFAR H5plot to 2.8.1.
* Update IDG to 011687ed.
* Update WSClean to 843f87c8.

**Fixes**
* Split-Directions runner now clones the master branch again.

## v4.5.0
Container will now follow flocs naming scheme: `flocs_vx.Y.Z_<march>_<mtune>_{mkl/aocl}[_cuda].sif`

**Updates**
* Add `bc`
* Add missing `--min_unflagged_fraction` option to  `create_ms_list.py`.
* Add [lotss-hba-survey](https://github.com/mhardcastle/lotss-hba-survey) scripts.
* Add `rename_MS_from_LTA.sh` for renaming files downloaded from the LTA through wget.
* Add `extract_MS_and_compress.sh` to extract MS tarballs, dysco compress them and remove the full resolution flags.
* Add example for the Split-Directions workflow as `run_lofar-vlbi-split-directions.sh`.
* `create_ms_list.py` will now check frequency coverage between LINC calibrator and target.
* Downgrade DP3 back to 161559ff to make DD solints work with model columns.
* Renamed `run_lofar-vlbi.sh` example to `run_lofar-vlbi-delay-calibration.sh`.
* Replace sub-sources-outside-region.py with facetselfcal version.
* Set the unflagged fraction limit for LINC to 5% in the example runner, because 50% is annoying.
* Update example runners to produce cleaner output. Temporary directory will now be renamed to `L<obsid>_<pipeline>` after a run, e.g. `L123456_LINC_calibrator`.
* Update ddf-pipeline to 712618b.
* Update LOFAR H5plot to 2.8.0.

**Fixes**
* Fix `filter_baselines` argument in LINC calibrator runner.
* Fix missing calibrator solutions argument in LINC target runner.
* Fix running LINC target without container.
* Fix some issues when using the runners without container argument.
* Include DP3 aoflagger update required to run delay calibration.

## v4.4.0
**Updates**
* Add `SciencePlots` Python package.
* Fix default baseline selection for LINC target.
* Custom LINC runners are now included, intended to be mildly user friendly and require no editing of scripts for default runs. See `run_LINC_calibrator.sh -h` and `run_LINC_target.sh -h`.
* Experimental VLBI-cwl runner included. See `run_lofar-vlbi.sh -h`.
* Update DP3 to `161559ff`.
* Update EveryBeam to `22cd113b`.
* Update WSClean to `a5b4e037`.

**Fixes**
* Do not remove lofarstman after installation.

## v4.3.1
**Updates**
* Add bces, bilby, nmmn, numdifftools and pymultinest
* Add nomacs image viewer
* Add LINC concatenation averageing options to create_mslist.py
* Clean up lofar-vlbi runner
* Update python-casacore to 3.5.2

## v4.3.0
**Updates**
* Add [RM-Tools](https://github.com/CIRADA-Tools/RM-Tools)
* Add [shadeMS](https://github.com/ratt-ru/shadeMS)
* Update AOCL to version 4
* Update `create_mslist.py` to include all LINC settings.
* Update DP3 to 161559ff
* Update EveryBeam to 22cd113b (support for MeerKAT beam)
* Update OpenBLAS to v0.3.22
* Update Toil to 5.10
* Update WSClean to 1c1c1d73 (support for MeerKAT beam)

**Fixes**
* Added missing MKL library path.
* Clean up LINC runners.
* Fix ddf-pipeline boostrap crash.

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
