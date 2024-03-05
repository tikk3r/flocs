---
title: Using the containers
layout: default
nav_order: 2
---

# Using containers
{: .no_toc}
This page describes basic usage of the LOFAR containers. For more detailed information about Apptainer in general, see the [Apptainer documentation](https://apptainer.org/docs/user/main/index.html).

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important}
> Directories that need to be accessible should be bound to the container by passing `--bind <dir1>,<dir2>,<dir3>` or `-B <dir1>,<dir2>,<dir3>` to either `apptainer shell` or `apptainer exec`. This directory binding is recursive.

{: .important}
> Environment variables that need to be accessible inside the container should either be set _after_ entering the container or set by using the `APPTAINERENV_` prefix _before_ entering the container. For example, defining `APPTAINERENV_MYVAR` will define `MYVAR` inside the container.
>
> If you need to add entries to PATH, this can be done by defining `APPTAINERENV_PREPEND_PATH` or `APPTAINERENV_APPEND_PATH` to, respecitvely, prepend or append values to `PATH`.

{: .warning}
> Pay attention to environmental settings that get passed to the container. Mixing (too much of) the host environment with the container environment can result in unexpected behaviour. Especially `PYTHONPATH` can wreak havoc if inherited from the host system. In a worst case scenario `--cleanenv` or `-c` can be used to clean the host environment before entering the container.

## Interactive use
The containers can act as your normal shell for interactive data reduction. To do so, use

```bash
apptainer shell <container>
```
This will provide a Bash shell with the software and Python environment loaded.

## Non-interactive use
Software can also be directly executed from the container. This is useful when interactive processing is not available or cumbersome, such as on clusters or for bulk processing. To directly execute something in the container, use

```bash
apptainer exec <container> <command> <arguments>
```
For example, compressing a Measurement Set with dysco using DP3 would be done as

```bash
apptainer exec <container> DP3 msin=input.ms msout=output.ms msout.storagemanager=dysco steps=[]
```
It is not restricted to individual commands. Pipelines or bash scripts that execute multiple commands can also be run this way.

## Pipeline use
Since FLoCs is geared towards running pipelines, runner scripts are available for [LINC](https://git.astron.nl/RD/LINC) and [VLBI-cwl](https://git.astron.nl/RD/VLBI-cwl). These CWL pipelines take a JSON configuration file as their input. This is generated via [`runners/create_ms_list.py`](https://github.com/tikk3r/flocs/blob/fedora-py3/runners/create_ms_list.py), which the runners will call automatically. This script generates the JSON configuration file with all the pipeline related settings initialised to their respective default settings. See the respecitve pipelines or `python create_ms_list.py -h` for available options. Running LINC or VLBI-cwl is then covered by calling the runner with `bash` _outside_ any container environment.

### LINC
The LINC pipeline consists of two parts: LINC calibrator and LINC target. The calibrator pipeline processes the flux density calibrator scans while target processes the target field. These respective pipelines can be run with [`runners/run_LINC_calibrator_HBA.sh`](https://github.com/tikk3r/flocs/blob/fedora-py3/runners/run_LINC_calibrator_HBA.sh) and [`runners/run_LINC_target_HBA.sh`](https://github.com/tikk3r/flocs/blob/fedora-py3/runners/run_LINC_target_HBA.sh). A user sets the container to use, where the data to process resides and for LINC target where the calibrator solutions can be found.

### VLBI-cwl
The VLBI-cwl pipeline consists of two parts: Delay-Calibration and Split-Directions. The former finds a suitable in-beam calibrator sources and performs direction independent calibration for the ILT's international stations. The latter, using the solutions from delay calibration, allows users to split out a number of directions of interest. Currently Delay-Calibration has a runner available under [`runners/run_lofar-vlbi-delay-calibration.sh`](https://github.com/tikk3r/flocs/blob/fedora-py3/runners/run_lofar-vlbi-delay-calibration.sh) and Split-Directions under [`runners/run_lofar-vlbi-spit-directions.sh`](https://github.com/tikk3r/flocs/blob/fedora-py3/runners/run_lofar-vlbi-split-directions.sh). A user sets the container to use, where the data to process resides and where the h5parm output by LINC *target* can be found.
