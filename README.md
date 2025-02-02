<img src="https://img.shields.io/github/v/release/tikk3r/lofar-grid-hpccloud?sort=semver"/><img src="https://img.shields.io/github/license/tikk3r/lofar-grid-hpccloud.svg?logo=github"/><a href="https://zenodo.org/badge/latestdoi/136925861"><img src="https://zenodo.org/badge/136925861.svg"/></a>

Please see https://tikk3r.github.io/flocs/ on how to use or obtain the containers.

Python versions that are end-of-life are not officially supported. See e.g. [this chart](https://devguide.python.org/versions/) for a quick look at which versions this entails.

# FLOCS

These containers, very creatively named “Frits’ LoFAR Containers” or FLoCs, package a collection of common LOFAR software that is used for imaging science with both Dutch and international array.

## CPU optimisations

The containers can be build to leverage specific CPU optimisations, by specifying the desired CPU architecture. It is highly recommended to avoid generic builds and build for `native` whenever possible, or at least the lowest common denominator architecture if you have a heterogenous environment. Furthermore, experiments with vendor-developed math libraries have shown promise in the past, therefore these containers optimise further in two additional ways:

1. If OpenBLAS is used, it will be built using the target architecture to leverage compiler optimisations.
2. The AMD recipe uses the AMD Optimizing CPU Libraries (AOCL) and the Intel recipe uses the Intel OneAPI Math Kernel Library (MKL) to leverate specific optimisations for the respective vendor's CPUs.

# Disclaimer

Be aware that these containers are my own work, and are not officially associated with any of the LOFAR software included in them. On rare occasion software may be running outside officially supported specifications. They may also be frozen to specific versions for a variety of reasons.
