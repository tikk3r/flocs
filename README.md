[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/1999)
<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/>
<img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/>
[![DOI](https://zenodo.org/badge/136925861.svg)](https://zenodo.org/badge/latestdoi/136925861)

# lofar-grid-hpccloud

This repository hold resources for deploying the LOFAR software (genericpipeline) and related tools through Singularity containers. These containers are general, but at the same time somewhat tailored for SKSP use.

The `master` branch is empty. Currently the images are based on the Fedora 34 Linux distribution, which is available from [DockerHub](https://hub.docker.com/_/fedora). Recipes to build this container can be found on the `fedora` branch.

Pre-built containers are public hosted at [SURFSara](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/). Sort by date to find the latest container there.

# Branches

**[fedora](https://github.com/tikk3r/lofar-grid-hpccloud/tree/fedora)** Fedora based recipes with a Python 2 environment for the genericpipeline framework. Some software may have to remain at older versions due to Python 2 compatibility.

**[fedora-py3](https://github.com/tikk3r/lofar-grid-hpccloud/tree/fedora-py3)** Fedora based recipes ditching Python 2. The genericpipeline framework is no longer included.
