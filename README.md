<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
<a href="https://zenodo.org/badge/latestdoi/136925861"><img src="https://zenodo.org/badge/136925861.svg"/></a>

# lofar-grid-hpccloud
This repository hold resources for deploying the LOFAR software (genericpipeline) and related tools through Singularity containers. These containers are general, but at the same time somewhat tailored for SKSP use.

The `master` branch is empty. Currently the images on this branch (`fedora-py3`) are based on the Fedora 34 Linux distribution, which is available from [DockerHub](https://hub.docker.com/_/fedora). 

As this branch no longer includes Python 2, the genericpipeline framework is _not_ included in these recipes anymore (see the [fedora branch](https://github.com/tikk3r/lofar-grid-hpccloud/tree/fedora) for that). Pipelines like prefactor are moving to CWL (to be included).

## Singularity
To build a full LOFAR Singularity image, do the following:

1) Turn on MKL and/or CUDA in **singularity/Singularity**, if desired, by setting `HAS_MKL=true` and/or `HAS_CUDA=true`. Set them to `false` if you do not require those.

2) Optimise your container for a desired architecture by updating the `MARCH` and `MTUNE` variables to the appropriate values. If you want to build for a generic machine, set these to `MARCH='x86-64'` and `MTUNE='generic'`, respectively.

3) Build **singulariy/Singularity** by running

        sudo SINGULARITY_CACHEDIR=$PWD SINGULARITY_TMPDIR=$PWD singularity build lofar_sksp.sif Singularity

Pre-built containers are public hosted at [SURFSara](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/). Sort by date to find the latest container there.

