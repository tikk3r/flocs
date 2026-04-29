---
title: FAQ
layout: default
nav_order: 99
---

# Frequently asked questions
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## I have found a problem or have a suggestion
First, read through the sections below in case it might be covered there. If it is not covered then open an issue on GitHub or contact me through email, Slack etc.

When reporting issues, seeking advice etc. avoid general "it doesn't work" statements. Try to provide at least the error message or traceback and how you are running or installing things. That provides valuable context to be able to figure out what the problem actually is. In case of bugs, a minimum working example (MWE) is extremely valuable.

## I see warnings about a build mismatch when starting a container.
If you see the following message when entering a container (bar specific values)

> WARNING - software has been built with -march=znver2 but current machine reports -march=bdver4.
> If you encounter strange behaviour or Illegal instruction warnings, consider building a container with the appropriate architecture set.
>
> WARNING - software has been built with -mtune=znver2 but current machine -mtune=bdver4.
> If you encounter strange behaviour or Illegal instruction warnings, consider building a container with the appropriate architecture set.

it means the container was built for a different CPU architecture than the machine you intend to run on. If the container was built with `-march=x86-64 -mtune=generic`, this warning should be safe to ignore. If any other mismatch is reported, successful software runs will depend on how far apart the target architecture and your architecture are in terms of supported features. Running older containers on newer hardware will generally work and even a newer generation does not necessarily guarantee problems. Your mileage may vary and you have three options: use at your own risk, obtain a container built for your architecture or obtain a generic container.

## My software crashes with "Illegal instruction"
The software you are trying to use was built for a different architecture than your machine. If you see the warning of the previous question, then this is probably the result of attempting to use an incompatible container. If you think that this is a bug and that it should work, feel free to open a [ticket](https://github.com/tikk3r/lofar-grid-hpccloud/issues).

## Directories have disappeared or software can't find files that exist.
If directories or files that exist on the host system cannot be found inside the container, double check if all the required directories have been passed along to `--bind/-B` before entering the container.

## Pipelines crash with "Too many open files".
Raise the open file limit. Certain steps like wide-band flagging with AOFlagger may need many files open simultaneously, which can lead to this error. In a Bash shell this limit can be checked by running `ulimit -n`. If this is set to a low value such as 1024, it is recommended to increase this. Usually `ulimit -n 4096` can be set without requiring special privileges. On CSH shells use `limit` to see current limits and `limit descriptors 4096` or `limit openfiles 4096` to increase it.

## Python imports or simple scripts fail
Did you patch `singularity.py` in your cwltool installation to prevent the `--no-eval` argument being passed to Apptainer? If not, this will prevent things environment variables from being expanded, meaning thing won't get mounted properly to the containers.

Another potential cause is that Python packages in your home directory can interfere with the container's Python installation. If Python imports fail (especially packages like NumPy or SciPy), pay close attention to the paths in the error messages. If you see paths that point to your home folder or your own Python installation, then that is a likely cause of issues. If you do need packages to be installed in your home directory, try using the container with the `--no-home` option which will not mount your home directory in the container. Note that this means nothing in your home directory will be accessible from inside the container. An alternative to installing packages directly in your home directory is to set up a venv and to use that instead.

## Pipelines fail to run JSHint mentioning "not a valid bind option" for e.g. /opt/lofar/LINC or similar
NodeJS is assumed to be installed. If not, it will download a container for it. This wil crash, because flocs-runners tries to automatically bind the pipelines to their respective directories in the container, which will only work for flocs containers. The solution is to install NodeJS. This is straighforward and requires no special permissions: https://nodejs.org/en/download.

## NodeJSEngine requires Node.js engine
Simiar to the previous one, NodeJS is assumed to be installed. If not, it will download a container for it. If you see an error like

```
The error was: NodeJSEngine requires Node.js engine to evaluate and validate Javascript expressions, but couldn't find it.  Tried nodejs, node, singularity run node:alpine
```

then it has somehow failed to find your NodeJS installation or failed to download the `node:alpine` container. The latter will faile because of the question right above this one. The simple solution is to install NodeJS. This is straighforward and requires no special permissions: https://nodejs.org/en/download.

## DDF-pipeline crashes with errors about e.g the ANTENNA column or weights
DP3 by default now compresses metadata via compression of the ANTENNA table, the UVW coordinates and writing only scalar flags. This is not compatible with the DDF-pipeline as included in flocs. The solution is to make a copy of your input data with DP3 using the options `msout.antennacompression=False msout.uvwcompression=False msout.scalarflags=False`. The DDF-pipeline runner will do this automatically.

## Crashes with JSONDecodeError or strange "File exists" errors
The crash will be something like reported in [LINC issue 100](https://git.astron.nl/RD/LINC/-/work_items/100). It might be a genuine bug, but I have found that this is generally caused by newer versions of Toil and cwltool. Especially if you see "File exists" errors where what should be temporary files are located in e.g. the results_LINC_target folder. The currently confirmed working combination of Toil and cwltool for the flocs runners is Toil 9.2.0 with cwltool 3.1.20251031082601. These are implemented in the dependencies as of 29/04/2026. Installing flocs runners should thus in principle give you the correct versions.
