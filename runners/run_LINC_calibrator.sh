#!/usr/bin/env bash
{
echo "=============================="
echo "=== LINC Calibrator Runner ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
HELP="$(basename $0) [-s <container path>] [-b <container bindpaths>] [-l <user-defined LINC>] [-r <running directory>] -d <data path>"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo $HELP
    exit 0
fi

while getopts ":d:s:r:l:b:" opt; do
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
        \?) echo "Invalid option -$OPTARG" >&2
            echo
            echo "Usage:"
            echo $HELP
        exit 1
        ;;
    esac

    case $OPTARG in
        -*) echo "$opt needs a valid argument"
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

## WORKDIR is where all the other directories will be stored.
WORKDIR=$(mktemp -d -p "$RUNDIR")
echo "Working directory is $WORKDIR"

## Final results will be copied here.
RESULTSDIR=$WORKDIR/results_LINC_calibrator/
## Logs of the various steps will be put here.
LOGSDIR=$WORKDIR/logs_LINC_calibrator/
## Temporary files are stored here.
## The trailing slash is important here.
TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/

if [[ -z "$LINC_DATA_ROOT" ]]; then
    LINC_DATA_ROOT=$WORKDIR/LINC
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
fi

# Prepare workflow files.
echo "Overriding rfistrategies with Lua >5.3 compatible ones from AOFlagger repository"
wget https://gitlab.com/aroffringa/aoflagger/-/raw/master/data/strategies/lofar-default.lua -O $LINC_DATA_ROOT/rfistrategies/lofar-default.lua

echo Making sure all scripts are executable
chmod 755 $LINC_DATA_ROOT/scripts/*.py

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

if [[ -z "$SIMG" ]]; then
    echo "No container specified."
    echo "Generating default pipeline configuration"
    wget --no-http-keep-alive https://raw.githubusercontent.com/tikk3r/flocs/fedora-py3/runners/create_ms_list.py
    python create_ms_list.py $DATADIR
    echo LINC starting
    echo export PYTHONPATH=\$LINC_DATA_ROOT/scripts:\$PYTHONPATH > tmprunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json' >> tmprunner.sh
    (time bash tmprunner.sh 2>&1) | tee $WORKDIR/job_output.txt
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
        export APPTAINERENV_EVERYBEAM_DATADIR=/opt/lofar/EveryBeam/share/everybeam/
    else
        export SINGULARITYENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export SINGULARITYENV_RESULTSDIR=$WORKDIR/results_LINC_calibrator/
        export SINGULARITYENV_LOGSDIR=$WORKDIR/logs_LINC_calibrator/
        export SINGULARITYENV_TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/
        export SINGULARITYENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts
        export SINGULARITYENV_EVERYBEAM_DATADIR=/opt/lofar/EveryBeam/share/everybeam/
    fi

    echo "Generating default pipeline configuration"
    wget --no-http-keep-alive https://raw.githubusercontent.com/tikk3r/flocs/fedora-py3/runners/create_ms_list.py
    singularity exec -B $PWD,$BINDPATHS $SIMG python create_ms_list.py $DATADIR
    echo LINC starting
    echo export PYTHONPATH=\$LINC_DATA_ROOT/scripts:\$PYTHONPATH > tmprunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json' >> tmprunner.sh
    (time singularity exec -B $PWD,$BINDPATHS $SIMG bash tmprunner.sh 2>&1) |& tee $WORKDIR/job_output_LINC_calibrator.txt
    echo LINC ended
fi
} |& tee job_output_full.txt
