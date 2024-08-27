#!/usr/bin/env bash
{
echo "=============================="
echo "===    VLBI-cwl Runner     ==="
echo "===   Delay-Calibration    ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
HELP="$(basename $0) [-s <container path>] [-b <container bindpaths>] [-l <user-defined LINC>] [-v <user-defined VLBI-cwl] [-r <running directory>] [-e<options for create_ms_list.py>] -d <data path> -c <VLBI solutions>"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo $HELP
    exit 0
fi

while getopts ":d:s:r:l:b:v:c:e:" opt; do
    case $opt in
        d) DATADIR="$OPTARG"
        ;;
        s) SIMG="$OPTARG"
        ;;
        b) BINDPATHS="$OPTARG"
        ;;
        r) RUNDIR="$OPTARG"
        ;;
        l) LINC_DATA_ROOT="$OPTARG"
        ;;
        v) VLBI_DATA_ROOT="$OPTARG"
        ;;
        c) DELAYSOLS="$OPTARG"
        ;;
        e) EXTRAOPTS="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            echo
            echo "Usage:"
            echo $HELP
        exit 1
        ;;
    esac
done

ulimit -S -n 30000

# Check if user gave sensible paths.
if [[ ! -d $DATADIR ]]; then
    echo "Data directory $DATADIR does not exist or is not accessible!"
    exit 2
else
    export DATADIR=$(readlink -f $DATADIR)
fi

if [[ ! -z "$SIMG" ]]; then
    if [[ ! -f $SIMG ]]; then
        echo "Container $SIMG does not exist or is not accessible!"
        exit 3
    fi
fi

if [[ ! -f $DELAYSOLS ]]; then
    echo "Calibrator solutions $DELAYSOLS do not exist or are not accessible!"
    exit 4
else
    export DATADIR=$(readlink -f $DATADIR)
    export DELAYSOLS=$(readlink -f $DELAYSOLS)
fi

if [[ -z $RUNDIR ]]; then
    echo "No running directory specified, running in $PWD"
    RUNDIR=$PWD
else
    echo "Using user-specified running directory $RUNDIR"
fi
export RUNDIR

# Automatically bind the data and runtime directories.
APPTAINER_BINDPATH=$RUNDIR,$DATADIR,$APPTAINER_BINDPATH
export APPTAINER_BINDPATH
echo "Binding the following paths to the container:"
sed 's/:/\n/g' <<< "$APPTAINER_BINDPATH"

# Warn on low disk space (< 25 TB).
reqSpace=15000000000000
reqSpaceHum=$(echo "scale=1;$reqSpace/1000000000000" | bc -l)T
availSpace=$(df $RUNDIR | awk 'NR==2 { print $4 }')
availSpaceHum=$(df -H $RUNDIR | awk 'NR==2 { print $4 }')
if (( availSpace < reqSpace )); then
    echo "!! WARNING !!"
    echo "!! WARNING !! only $availSpaceHum of available disk space detected!"
    echo "!! WARNING !! at least $reqSpaceHum is recommended for a dysco-compressed 8 hour dataset."
    echo "!! WARNING !!"
fi

## WORKDIR is where all the other directories will be stored.
export WORKDIR=$(mktemp -d -p "$RUNDIR")
## Location of LINC. This must be a user-writable location for this wrapper script.
## If it does not exist, this script will attempt to clone the LINC repository to the given path.
if [[ -z "$LINC_DATA_ROOT" ]]; then
    LINC_DATA_ROOT=$WORKDIR/LINC
fi
if [[ -z "$VLBI_DATA_ROOT" ]]; then
    VLBI_DATA_ROOT=$WORKDIR/VLBI_cwl
fi
LOFAR_HELPERS_ROOT=$WORKDIR/lofar_helpers
FACETSELFCAL_ROOT=$WORKDIR/lofar_facet_selfcal

## Final results will be copied here.
export RESULTSDIR=$WORKDIR/results_VLBI_CWL
## Logs of the various steps will be put here.
export LOGSDIR=$WORKDIR/logs_VLBI_CWL
## Temporary files are stored here.
## The trailing slash is important here.
export TMPDIR=$WORKDIR/tmpdir_VLBI_CWL/

export LINC_DATA_ROOT=$(readlink -f $LINC_DATA_ROOT)
export VLBI_DATA_ROOT=$(readlink -f $VLBI_DATA_ROOT)
git clone https://github.com/jurjen93/lofar_helpers.git $LOFAR_HELPERS_ROOT
git clone https://github.com/rvweeren/lofar_facet_selfcal.git $FACETSELFCAL_ROOT

# Check if LINC directory exists or is valid.
if [ ! -d $LINC_DATA_ROOT ]; then
    echo $LINC_DATA_ROOT does not exist and will be created. Cloning LINC...
    mkdir -p $LINC_DATA_ROOT
    git clone https://git.astron.nl/RD/LINC.git $LINC_DATA_ROOT
fi
# If the directory exists, check if it is empty.
if [ -d $LINC_DATA_ROOT ] && [ ! -d $LINC_DATA_ROOT/steps ]; then
    echo $LINC_DATA_ROOT exists, but is empty. Cloning LINC...
    git clone https://git.astron.nl/RD/LINC.git $LINC_DATA_ROOT
fi
# If the directory is not empty, check if it contains LINC
if [ -d $LINC_DATA_ROOT ] && [ ! -d $LINC_DATA_ROOT/steps ]; then
    echo WARNING: $LINC_DATA_ROOT is not empty, but required LINC folders are not found.
    exit 1
elif [ -d $LINC_DATA_ROOT ] && [ -d $LINC_DATA_ROOT/steps ]; then
    echo $LINC_DATA_ROOT exists and seems to contain LINC. Continueing...
fi

# Check if VLBI directory exists or is valid.
if [ ! -d $VLBI_DATA_ROOT ]; then
    echo $VLBI_DATA_ROOT does not exist and will be created. Cloning VLBI-cwl...
    mkdir -p $VLBI_DATA_ROOT
    git clone https://git.astron.nl/RD/VLBI-cwl.git $VLBI_DATA_ROOT
elif [ -d $VLBI_DATA_ROOT ] && [ ! -d $VLBI_DATA_ROOT/steps ]; then
    echo $VLBI_DATA_ROOT exists, but is empty. Cloning VLBI-cwl...
    git clone https://git.astron.nl/RD/VLBI-cwl.git $VLBI_DATA_ROOT
fi
# If the directory is not empty, check if it contains VLBI-cwl
if [ -d $VLBI_DATA_ROOT ] && [ ! -d $VLBI_DATA_ROOT/steps ]; then
    echo WARNING: $VLBI_DATA_ROOT is not empty, but required VLBI-cwl folders are not found.
    exit 1
elif [ -d $VLBI_DATA_ROOT ] && [ -d $VLBI_DATA_ROOT/steps ]; then
    echo $VLBI_DATA_ROOT exists and seems to contain VLBI-cwl. Continueing...
fi

# Obtain LINC commit used
cd $LINC_DATA_ROOT
export LINC_COMMIT=$(git rev-parse --short HEAD)
cd -

# Obtain LOFAR-VLBI commit used
cd $VLBI_DATA_ROOT
export VLBI_COMMIT=$(git rev-parse --short HEAD)
cd -

# Prepare workflow files.
sed -i "s/PREFACTOR_DATA_ROOT/LINC_DATA_ROOT/" $VLBI_DATA_ROOT/steps/*.cwl

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

if [[ -z "$SIMG" ]]; then
    echo "No container specified. Toil runners require a container."
    exit
else
    echo "Using container $SIMG"
    # Pass along necessary variables to the container.
    APPTAINER_BINDPATH="$VLBI_DATA_ROOT:/opt/lofar/VLBI-cwl/,$LINC_DATA_ROOT:/opt/lofar/LINC/,$APPTAINER_BINDPATH"
    mkdir -p $WORKDIR/simgcache/pull/
    cp $SIMG $WORKDIR/simgcache/lofar_vlbi.sif

    CONTAINERSTR=$(singularity --version)
    if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
        export APPTAINER_CACHEDIR=/cosma/apps/do011/dc-swei1/containers/
        export APPTAINER_PULLDIR=/cosma/apps/do011/dc-swei1/containers/pull
        export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
        export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
        export APPTAINERENV_RESULTSDIR=$RESULTSDIR
        export APPTAINERENV_LOGSDIR=$LOGSDIR
        export APPTAINERENV_TMPDIR=$TMPDIR
        export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
        export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:\$PYTHONPATH
        export APPTAINER_SHELL=/bin/bash
    else
        export SINGULARITY_CACHEDIR=$WORKDIR/simgcache
        export SINGULARITY_PULLDIR=$WORKDIR/simgcache/pull
        export CWL_SINGULARITY_CACHE=$SINGULARITY_CACHEDIR
        export SINGULARITYENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export SINGULARITYENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
        export SINGULARITYENV_RESULTSDIR=$RESULTSDIR
        export SINGULARITYENV_LOGSDIR=$LOGSDIR
        export SINGULARITYENV_TMPDIR=$TMPDIR
        export SINGULARITYENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
        export SINGULARITYENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:\$PYTHONPATH
        export SINGULARITY_SHELL=/bin/bash
    fi

    pattern="${DATADIR}/*.MS"
    files=( $pattern )
    ms="${files[0]}"  # printf is safer!
    wget https://raw.githubusercontent.com/lmorabit/lofar-vlbi/master/plot_field.py
    singularity exec -B $PWD,$BINDPATHS $SIMG python plot_field.py --MS $ms

    git clone https://github.com/tikk3r/flocs.git

    export TOIL_CHECK_ENV=True
    mkdir -p $WORKDIR/coordination
    export JOBSTORE=$WORKDIR/jobstore
    export TOIL_SLURM_ARGS="--export=ALL -A do011 -p dine2,cosma8-ska2 -t 24:00:00"
    mkdir $LOGSDIR/slurmlogs

    head -n 10 image_catalogue.csv > image_catalogue_top10.csv

    singularity exec -B $PWD,$BINDPATHS $SIMG python flocs/runners/create_ms_list.py VLBI split-directions --delay_solset=$DELAYSOLS --do_selfcal=True --configfile=$VLBI_DATA_ROOT/facetselfcal_config_target.txt --h5merger=$LOFAR_HELPERS_ROOT --selfcal=$FACETSELFCAL_ROOT --image_cat=image_catalogue_top10.csv --linc=$LINC_DATA_ROOT $EXTRAOPTS $DATADIR

    echo VLBI-cwl starting
    toil-cwl-runner \
    --no-read-only \
    --retryCount 0 \
    --singularity \
    --disableCaching \
    --writeLogsFromAllJobs True \
    --logFile full_log.log \
    --writeLogs ${LOGSDIR} \
    --outdir ${RESULTSDIR} \
    --tmp-outdir-prefix "${TMPDIR}/" \
    --jobStore ${JOBSTORE} \
    --workDir ${WORKDIR} \
    --coordinationDir ${WORKDIR}/coordination \
    --tmpdir-prefix "${TMPDIR}/" \
    --disableAutoDeployment True \
    --bypass-file-store \
    --preserve-entire-environment \
    --batchSystem slurm \
    --batchLogsDir $LOGSDIR/slurmlogs \
    --no-compute-checksum \
    #--setEnv PYTHONPATH=$VLBI_DATA_ROOT/scripts:\$PYTHONPATH \
    $VLBI_DATA_ROOT/workflows/alternative_workflows/split-directions-toil.cwl \
    mslist_VLBI_split_directions.json
    echo VLBI-cwl ended
fi
echo Cleaning up...
echo == Deleting LOFAR-VLBI tmpdir..
#rm -rf $WORKDIR/tmpdir_VLBI_CWL/

echo == Moving results...
FINALDIR=$(dirname $WORKDIR)
pattern="${DATADIR}/*.MS"
files=( $pattern )
ms="${files[0]}"  # printf is safer!
obsid=$(echo $(basename $ms) | awk -F'_' '{print $1}')
mv "$WORKDIR" "$FINALDIR/${obsid}_LOFAR-VLBI_Split-Directions"

echo "==========================="
echo "=== LOFAR-VLBI  Summary ==="
echo "==========================="
echo LINC version:       $LINC_COMMIT
echo LOFAR-VLBI version: $VLBI_COMMIT
echo Output:             "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration"
echo Solutions:          "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration/results_VLBI_CWL/*h5"
echo Inspection plots:   "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration/results_VLBI_CWL/inspection"
echo Pipeline logs:      "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration/logs_VLBI_CWL"
echo Pipeline summary:   "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration/logs_VLBI_CWL/*summary.log"
} |& tee job_output_full.txt
