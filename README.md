<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
<a href="https://zenodo.org/badge/latestdoi/136925861"><img src="https://zenodo.org/badge/136925861.svg"/></a>

# lofar-grid-hpccloud

This repository hold resources for deploying the LOFAR software (genericpipeline) and related tools through Singularity containers. These containers are general, but at the same time somewhat tailored for SKSP use.

The `master` branch is empty. Currently the images are based on the Fedora 31 Linux distribution, which is available from [DockerHub](https://hub.docker.com/_/fedora). Recipes to build this container can be found on the `fedora` branch.

To build a full LOFAR Singularity image, do the following:

1) Turn on MKL and/or CUDA in **Singularity.lofar\_sksp\_full**, if desired, by setting `HAS_MKL=true` and/or `HAS_CUDA=true`. Set them to `false` if you do not require those.

2) Optimise your container for a desired architecture by updating the `NOAVX512` or `MARCH` and `MTUNE` variables to the appropriate values in **Singularity.lofar\_sksp\_full**. If you want to build for a generic machine, set these to `NOAVX512=true`, `MARCH='x86-64'` and `MTUNE='generic'`, respectively.

3) Build **Singularity.lofar\_sksp\_full** by running

        sudo SINGULARITY_CACHEDIR=$PWD SINGULARITY_TMPDIR=$PWD singularity build lofar_sksp_full.sif Singularity.lofar_sksp_full


4) Use `Bootstrap: localimage` in **Singularity.lofar\_sksp\_ddf\_public** and point it to the previous container using `From: /path/to/base.sif`. Then build the ddf container using

        sudo SINGULARITY_CACHEDIR=$PWD SINGULARITY_TMPDIR=$PWD singularity build lofar_sksp_full_ddf_public.sif Singularity.lofar_sksp_ddf_public

Pre-built containers are public hosted at [SURFSara](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/). Sort by date to find the latest container there.
