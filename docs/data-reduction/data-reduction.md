---
title: Running pipelines through flocs
layout: default
nav_order: 4
has_children: true
---

# Using flocs
{: .no_toc}
This page describes basic usage of the pipeline runners available through `flocs-run`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Installing flocs
Flocs provides pipeline runners that can be installed via package managers. For example:

```bash
uv pip install git+https://github.com/FLOCSoft/flocs-runners.git
```

This should provide you with `flocs-run`; the main entry point to generating configuration files and running pipelines.

# Running pipelines

{: .important}
> Currently `cwltool` adds `--no-eval` to Apptainer calls. This prevents environment variables from being expanded, making modifications like `APPTAINER_PYTHONPATH=/something/new:\$PYTHONPATH` not possible. At the moment, my suggested workaroud is to simply edit your installation by opening `/path/to/your/packages/cwltool/singularity.py` and remove the two lines that add this (currently 495-495). To find where you installation lives, you can run e.g. `python -c "import cwltool; print(cwltool.__file__)"`.


Since FLoCs is in principle built for running pipelines with, pipeline runners are provided for [LINC](https://git.astron.nl/RD/LINC) and [VLBI-cwl](https://git.astron.nl/RD/VLBI-cwl). These CWL pipelines take a JSON configuration file as their input. Running pipelines is abstracted away behind the `flocs-run` executable, so users should not have to interact with JSON or CWL files directly. First install flocs as explained above. Secondly, ensure `LINC_DATA_ROOT` and `VLBI_DATA_ROOT` are defined in your environment. As LINC is the most basic pipeline and contains skymodels of e.g. the A-Team, flocs demands that this variable is defined. If you are only running LINC, `VLBI_DATA_ROOT` has to be defined, but isn't used; set it to whatever. To see what options are available, use `--help` for the main command or each sub command.

## Generating JSON configurations only.
Previously `create_ms_list.py` was used to generate configuration files for either LINC or VLBI-cwl, in JSON format. This has been deprecated. Instead, use the `--config-only` option of the respective pipeline. With this option, `flocs-run` stops after generating the configuration file and will not execute a pipeline. Otherwise options are indentical to what is described below.

## Running pipelines
### LINC
The flocs LINC runner can be used to run the **HBA** calibrator or target pipelines. LBA is not supported. In its most basic form, the calibrator pipeline can be executed within a container as follows:

```bash
flocs-run linc calibrator </folder/with/mses/>
```

and the target pipeline as

```bash
flocs-run linc target --cal-solutions </path/to/calibrator/cal_solutions.h5> </folder/with/mses/>
```

This will execute the pipeline in the given container, using `cwltool` as the CWL runner. For VLBI data reduction, you will almost always want to use the `--output-fullres-data` option (this may become default later).

### VLBI
To run VLBI delay calibration after LINC, for example, use

```bash
flocs-run vlbi delay-calibration --ms_suffix dp3concat </folder/with/mses/>
```
This assumes you ran LINC target with the `--output-fullres-data` option.

## Using containers/Toil/Slurm/all of the above
`flocs-run` intends to make it easy for the user to switch between `cwltool`, `toil-cwl-runner`, running on a local machine, or running on a Slurm cluster. These are controlled by a set of options common to all the pipelines. The recommended way to use the runners is to install it in your own environment and pass a container to run a pipeline, and not use it from within a container.

### Switching CWL runners
Two CWL runners are supported currently: `cwltool` and `toil-cwl-runner`. The runner of choice can be selected via the `--runner` option. It defaults to `cwltool`, but choosing `toil` will run the workflow with `toil-cwl-runner`. Note that for full compatability with all LINC and VLBI-cwl pipelines, Toil 9 or newer is required.

### Switching between Slurm and a local machine
The `--scheduler` option changes whether the pipeline is executed on the machine that executes `flocs-run`, or whether it interacts with the Slurm scheduler. Choosing `singleMachine` will execute it on the local machine (default). Choosing `slurm` will use a Slurm queue. Users must realise that this means something *different* between cwltool and toil: if the runner is `cwltool`, a jobscript is created and submitted to the queue via `sbatch`. The pipeline will then be executed *on the worker machine*. If the runner is `toil`, it will setup Toil's Slurm-related settings and variables and execute `toil-cwl-runner` in Slurm mode *on the current machine*. Slurm resource requirements are managed via the `--slurm-{account,cores,time,queue}` options.

### Using an Apptainer container
Using an Apptainer container requires the same setup for both `cwltool` or `toil`. This is described in this section. Directories that need to be bound should currently be defined via `APPTAINER_BINDPATH` environment variable. This currently has no effect on workflows executed with Toil.

Firstly, containers have to adhere to a specific name. For LINC it **must** be named `astronrd_linc_latest.sif` and for VLBI-cwl it **must** be named `vlbi-cwl_latest.sif`. The easiest way to swap out containers is to make symlinks with these names that point to your desired container, in the directories that will be described next. You have to define three environment variables:

* `APPTAINER_CACHEDIR`: this is where cached containers live. Consider this semi-permanent.
* `APPTAINER_PULLDIR`: set this to `$APPTAINER_CACHEDIR/pull`. If a container with one of the above names is found here for LINC or VLBI-cwl, it will not try to pull it. Otherwise it will try to pull it from DockerHub (which will fail for VLBI-cwl).
* `CWL_SINGULARITY_CACHE`: set this to `$APPTAINER_CACHEDIR`

Once those are defined, put the containers (or a symlink to them) under `$APPTAINER_CACHEDIR` and `$APPTAINER_PULLDIR`. A pipeline run using toil and Slurm will look something like this:

```bash
flocs-run vlbi delay-calibration --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount --ms_suffix dp3concat </folder/with/mses/>
```

A pipeline run using cwltool and Slurm will look something like this:

```bash
flocs-run vlbi delay-calibration --runner cwltool --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount --ms_suffix dp3concat </folder/with/mses/>
```

this will wrap a cwltool call in the appropriate Slurm script and submit the whole thing as a job to the slurm queue via `sbatch`.


### Example back to back runs
After the setup above has been completed, and assuming everything runs perfectly (YMMV), an example of reducing data from LTA to delay calibration on a Slurm managed cluster will look something like this:

```bash
flocs-run linc calibrator --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount </folder/with/mses/>
flocs-run linc target --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount </folder/with/mses/> </path/to/calibrator/cal_solutions.h5>
flocs-run vlbi delay-calibration --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount --ms_suffix dp3concat </path/to/target/results/>
```

When a LINC run finishes a final copy named e.g. `LINC_calibrator_<date>` should be created in the directory where the run was started.

If you find a bug or have requests for functionality, please report it on the GitHub issue tracker.

## Extracting profiling information with Toil

The Toil cwl runner has the option to record statistics like RAM usage and core hours used via its `--stats` option. If using `--runner toil`, passing the `--record-toil-stats` option will enable this flag and leave the jobstore behind. N.B. that Toil disables cleanup of succesful steps when doing this, meaning a (potentially large) amount of disk space is temporarily in use (flocs should still cleanup after a successful run, so this is mainly important to consider _during_ the run or running many jobs collecting statistics at once).

Gathering the recorded statistics can then be done via the `toil stats` command. For example, dumping these as a JSON file can be done like `toil stats --raw /path/to/jobstore > stats.json`. If you used `flocs-run` the jobstore will be inside the finished copy (for LINC only at the moment) or the corresponding temporary directory.
