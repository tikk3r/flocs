#!/usr/bin/env bash
{
echo "=============================="
echo "=== LINC Calibrator Runner ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
HELP="$(basename $0) [-s <container path>] [-b <container bindpaths>] [-l <user-defined LINC>] [-r <running directory>] [-e <options for create_ms_list.py>] -d <data path>"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo $HELP
    exit 0
fi

while getopts ":d:s:r:l:b:e:" opt; do
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
        e) EXTRAOPTS="$OPTARG'"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            echo
            echo "Usage:"
            echo $HELP
        exit 1
        ;;
    esac
done

# Check if user gave sensible paths.
if [[ ! -d $DATADIR ]]; then
    echo "Data directory $DATADIR does not exist or is not accessible!"
    exit 2
else
    export DATADIR=$(readlink -f $DATADIR)
fi

if [[ ! -z "$SIMG" ]]; then
    if [[ ! -f $SIMG ]]; then
        echo "Container $DATADIR does not exist or is not accessible!"
        exit 3
    fi
fi

if [[ -z $RUNDIR ]]; then
    echo "No running directory specified, running in $PWD"
    RUNDIR=$PWD
else
    echo "Using user-specified running directory $RUNDIR"
fi
export RUNDIR

## WORKDIR is where all the other directories will be stored.
export WORKDIR=$(mktemp -d -p "$RUNDIR")
echo "Working directory is $WORKDIR"

## Final results will be copied here.
export RESULTSDIR=$WORKDIR/results_LINC_calibrator/
## Logs of the various steps will be put here.
export LOGSDIR=$WORKDIR/logs_LINC_calibrator/
## Temporary files are stored here.
## The trailing slash is important here.
export TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/

if [[ -z "$LINC_DATA_ROOT" ]]; then
    export LINC_DATA_ROOT=$WORKDIR/LINC
fi
# Check if LINC directory exists or is valid.
if [ ! -d $LINC_DATA_ROOT ]; then
    echo $LINC_DATA_ROOT does not exist and will be created. Cloning LINC...
    mkdir -p $LINC_DATA_ROOT
    git clone https://git.astron.nl/RD/LINC.git $LINC_DATA_ROOT
fi

# If the directory is not empty, check if it contains LINC
if [ -d $LINC_DATA_ROOT ] && [ ! -d $LINC_DATA_ROOT/steps ]; then
    echo WARNING: $LINC_DATA_ROOT is not empty, but required LINC folders are not found.
    exit 1
elif [ -d $LINC_DATA_ROOT ] && [ -d $LINC_DATA_ROOT/steps ]; then
    echo $LINC_DATA_ROOT exists and seems to contain LINC. Continuing...
    export LINC_DATA_ROOT
fi

# Obtain LINC commit used
cd $LINC_DATA_ROOT
export LINC_COMMIT=$(git rev-parse --short HEAD)
cd -

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

if [[ -z "$SIMG" ]]; then
    echo "No container specified."
    echo "Generating default pipeline configuration"
    git clone https://github.com/tikk3r/flocs.git

    python flocs/runners/create_ms_list.py  --filter_baselines '*&' $EXTRAOPTS $DATADIR
    echo LINC starting
    echo export PATH=$LINC_DATA_ROOT/scripts:$PATH > jobrunner.sh
    echo export PYTHONPATH=\$LINC_DATA_ROOT/scripts:\$PYTHONPATH >> jobrunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json' >> jobrunner.sh
    (time bash jobrunner.sh 2>&1) | tee $WORKDIR/job_output_linc-calibrator.txt
    echo LINC ended
else
    echo "Using container $SIMG"
    # Pass along necessary variables to the container.
    CONTAINERSTR=$(singularity --version)
    if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
        export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export APPTAINERENV_RESULTSDIR=$WORKDIR/results_LINC_calibrator/
        export APPTAINERENV_LOGSDIR=$WORKDIR/logs_LINC_calibrator/
        export APPTAINERENV_TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/
        export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts
    else
        export SINGULARITYENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export SINGULARITYENV_RESULTSDIR=$WORKDIR/results_LINC_calibrator/
        export SINGULARITYENV_LOGSDIR=$WORKDIR/logs_LINC_calibrator/
        export SINGULARITYENV_TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/
        export SINGULARITYENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts
    fi

    echo "Generating default pipeline configuration"
    git clone https://github.com/tikk3r/flocs.git

    singularity exec -B $PWD,$BINDPATHS $SIMG python flocs/runners/create_ms_list.py --filter_baselines '*&' $EXTRAOPTS $DATADIR
    echo LINC starting
    echo export PYTHONPATH=\$LINC_DATA_ROOT/scripts:\$PYTHONPATH > jobrunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json' >> jobrunner.sh
    (time singularity exec -B $PWD,$BINDPATHS $SIMG bash jobrunner.sh 2>&1) |& tee $WORKDIR/job_output_linc-calibrator.txt
    echo LINC ended
fi
echo Cleaning up...
echo == Deleting LINC tmpdir..
rm -rf $WORKDIR/tmpdir_LINC_calibrator

echo == Moving results...
FINALDIR=$(dirname $WORKDIR)
pattern="${DATADIR}/*.MS"
files=( $pattern )
ms="${files[0]}"  # printf is safer!
obsid=$(echo $(basename $ms) | awk -F'_' '{print $1}')
mv "$WORKDIR" "$FINALDIR/${obsid}_LINC_calibrator"

echo "==============================="
echo "=== LINC Calibrator Summary ==="
echo "==============================="
echo LINC version:      $LINC_COMMIT
echo Output:            "$FINALDIR/${obsid}_LINC_calibrator"
echo Solutions:         "$FINALDIR/${obsid}_LINC_calibrator/results_LINC_calibrator/*h5"
echo Inspection plots:  "$FINALDIR/${obsid}_LINC_calibrator/results_LINC_calibrator/inspection"
echo Pipeline logs:     "$FINALDIR/${obsid}_LINC_calibrator/results_LINC_calibrator/logs"
echo Pipeline summary:  "$FINALDIR/${obsid}_LINC_calibrator/results_LINC_calibrator/logs/*summary.log"
} |& tee job_output_full.txt
