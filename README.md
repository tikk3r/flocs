[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/1999)
<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
[![DOI](https://zenodo.org/badge/136925861.svg)](https://zenodo.org/badge/latestdoi/136925861)

# lofar-grid-hpccloud

This repository hold resources for deploying the LOFAR software (genericpipeline) and related tools through Singularity containers. These containers are general, but at the same time somewhat tailored for SKSP use.

The `master` branch is empty. Currently the images are based on the Fedora 27 Linux distribution, which is available from [DockerHub](https://hub.docker.com/_/fedora). Recipes to build this container can be found on the `fedora` branch.

To build a full LOFAR Singularity image, do the following:
1) Build Singularity.lofarbase

    sudo singularity build lofar_sksp_base.sif Singularity.lofar_sksp_base

2) Build Singularity.lofar (use the `From: localimage` part instead of the Singularity Hub part)

    sudo singularity build lofar_sksp.sif Singularity.lofar_sksp

Pre-built containers are public hosted at [SURFSara](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/). Sort by date to find the latest container there.

For buid purposes `lofar_sksp_base` and `lofar_sksp` are available on Singularity-hub, and can be downloaded with

    singularity pull --name customname.sif shub://tikk3r/lofar-grid-hpccloud:<image>[@<specific hash>]

The hash is optional. By default the latest version is downloaded. An example command is `singularity pull --name lofar.simg shub://tikk3r/lofar-grid-hpccloud:lofar_sksp`.

**Please do \_NOT\_ pull from Singularity Hub unless absolutely necessary. Downloads are rate limited to 100 per week.**


Visit the  [wiki](https://github.com/tikk3r/lofar-grid-hpccloud/wiki) for more detailed information and build instructions.

