<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
<a href="https://zenodo.org/badge/latestdoi/136925861"><img src="https://zenodo.org/badge/136925861.svg"/></a>

# lofar-grid-hpccloud

This repository hold resources for deploying the LOFAR software (genericpipeline) and related tools through Singularity containers. These containers are general, but at the same time somewhat tailored for SKSP use.

The `master` branch is empty. Currently the images are based on the Fedora 31 Linux distribution, which is available from [DockerHub](https://hub.docker.com/_/fedora). Recipes to build this container can be found on the `fedora` branch.

To build a full LOFAR Singularity image, do the following:

1) Turn on MKL and/or CUDA in Singularity.lofar\_sksp\_base, if desired, by setting `HAS_MKL=true` and/or `HAS_CUDA=true`. Set them to `false` if you do not require those.

2) Build Singularity.lofar_sksp_base by running

    sudo SINGULARITY_CACHEDIR=$PWD SINGULARITY_TMPDIR=$PWD singularity build lofar_sksp_base.sif Singularity.lofar_sksp_base

3) Optimise your container for a desired architecture by updating the `MARCH` and `MTUNE` variables to the appropriate values. If you want to build for a generic machine, set these to `MARCH='x86-64'` and `MTUNE='generic'`, respectively.

4) Use `Bootstrap: localimage` in Singularity.lofar_sksp and point it to the base container using `From: /path/to/base.sif`. Then build the main container using

    sudo SINGULARITY_CACHEDIR=$PWD SINGULARITY_TMPDIR=$PWD singularity build lofar_sksp.sif Singularity.lofar_sksp

Pre-built containers are public hosted at [SURFSara](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/). Sort by date to find the latest container there.
