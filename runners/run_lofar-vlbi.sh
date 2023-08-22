#!/usr/bin/env bash
{
echo "=============================="
echo "===    VLBI-cwl Runner     ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
HELP="$(basename $0) [-s <container path>] [-b <container bindpaths>] [-l <user-defined LINC>] [-v <user-defined VLBI-cwl] [-r <running directory>] -d <data path> -c <calibrator solutions>"
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo $HELP
    exit 0
fi

while getopts ":d:s:r:l:b:v:c:" opt; do
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
        c) TARGETSOLS="$OPTARG"
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

if [[ ! -f $TARGETSOLS ]]; then
    echo "Calibrator solutions $TARGETSOLS do not exist or are not accessible!"
    exit 4
else
    export DATADIR=$(readlink -f $DATADIR)
fi

if [[ -z $RUNDIR ]]; then
    echo "No running directory specified, running in $PWD"
    RUNDIR=$PWD
else
    echo "Using user-specified running directory $RUNDIR"
fi

## WORKDIR is where all the other directories will be stored.
WORKDIR=$(mktemp -d -p "$RUNDIR")
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
RESULTSDIR=$WORKDIR/results_VLBI_CWL
## Logs of the various steps will be put here.
LOGSDIR=$WORKDIR/logs_VLBI_CWL
## Temporary files are stored here.
## The trailing slash is important here.
TMPDIR=$WORKDIR/tmpdir_VLBI_CWL/

export LINC_DATA_ROOT
export VLBI_DATA_ROOT
git clone https://github.com/jurjen93/lofar_helpers.git $LOFAR_HELPERS_ROOT
git clone https://github.com/rvweeren/lofar_facet_selfcal.git $FACETSELFCAL_ROOT
sed -i '7704d' $FACETSELFCAL_ROOT/facetselfcal.py

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
fi
# If the directory exists, check if it is empty.
if [ -d $VLBI_DATA_ROOT ] && [ ! -d $VLBI_DATA_ROOT/steps ]; then
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

# Prepare workflow files.
sed -i "s/PREFACTOR_DATA_ROOT/LINC_DATA_ROOT/" $VLBI_DATA_ROOT/steps/*.cwl

echo "Overriding rfistrategies with Lua >5.3 compatible ones from AOFlagger repository"
wget https://gitlab.com/aroffringa/aoflagger/-/raw/master/data/strategies/lofar-default.lua -O $LINC_DATA_ROOT/rfistrategies/lofar-default.lua

echo Making sure all scripts are executable
chmod 755 $LINC_DATA_ROOT/scripts/*.py

echo Making sure all shebang lines use /usr/bin/env python instead of /usr/bin/env
for f in $LINC_DATA_ROOT/scripts/*.py; do
    sed -i "s?\#\!/usr/bin/python?\#\!/usr/bin/env python?" $f
done

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

if [[ -z "$SIMG" ]]; then
    echo "No container specified."

    pattern="${DATADIR}/*.MS"
    files=( $pattern )
    ms="${files[0]}"  # printf is safer!
    wget https://raw.githubusercontent.com/lmorabit/lofar-vlbi/master/plot_field.py
    python plot_field.py --MS $ms

    git clone https://github.com/tikk3r/flocs.git

    python flocs/runners/create_ms_list.py $DATADIR --vlbi --solset=$TARGETSOLS --configfile=$VLBI_DATA_ROOT/facetselfcal_config.txt --h5merger=$LOFAR_HELPERS_ROOT --facetselfcal=$FACETSELFCAL_ROOT

    echo VLBI-cwl starting
    # Switch to a non-GUI backend to avoid plotting issues.
    echo export MPLBACKEND='Agg' > tmprunner.sh
    echo export PYTHONPATH=\$VLBI_DATA_ROOT/scripts:\$LINC_DATA_ROOT/scripts:\$PYTHONPATH >> tmprunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $VLBI_DATA_ROOT/workflows/delay-calibration.cwl mslist.json 2>&1' >> tmprunner.sh
    (time bash tmprunner.sh) |& tee $WORKDIR/job_output_test.txt
    echo VLBI-cwl ended
else
    echo "Using container $SIMG"
    # Pass along necessary variables to the container.

    CONTAINERSTR=$(singularity --version)
    if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
        export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
        export APPTAINERENV_RESULTSDIR=$RESULTSDIR
        export APPTAINERENV_LOGSDIR=$LOGSDIR
        export APPTAINERENV_TMPDIR=$TMPDIR
        export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
    else
        export SINGULARITYENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
        export SINGULARITYENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
        export SINGULARITYENV_RESULTSDIR=$RESULTSDIR
        export SINGULARITYENV_LOGSDIR=$LOGSDIR
        export SINGULARITYENV_TMPDIR=$TMPDIR
        export SINGULARITYENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
    fi

    pattern="${DATADIR}/*.MS"
    files=( $pattern )
    ms="${files[0]}"  # printf is safer!
    wget https://raw.githubusercontent.com/lmorabit/lofar-vlbi/master/plot_field.py
    singularity exec -B $PWD,$BINDPATHS $SIMG python plot_field.py --MS $ms

    git clone https://github.com/tikk3r/flocs.git

    singularity exec -B $PWD,$BINDPATHS $SIMG python flocs/runners/create_ms_list.py $DATADIR --vlbi --solset=$TARGETSOLS --configfile=$VLBI_DATA_ROOT/facetselfcal_config.txt --h5merger=$LOFAR_HELPERS_ROOT --facetselfcal=$FACETSELFCAL_ROOT --delay_calibrator=delay_calibrators.csv

    echo VLBI-cwl starting
    # Switch to a non-GUI backend to avoid plotting issues.
    echo export MPLBACKEND='Agg' > tmprunner.sh
    echo export PYTHONPATH=\$VLBI_DATA_ROOT/scripts:\$LINC_DATA_ROOT/scripts:\$PYTHONPATH >> tmprunner.sh
    echo 'cwltool --leave-tmpdir --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $VLBI_DATA_ROOT/workflows/delay-calibration.cwl mslist.json 2>&1' >> tmprunner.sh
    (time singularity exec -B $PWD,$BINDPATHS $SIMG bash tmprunner.sh) |& tee $WORKDIR/job_output_vlbi-cwl.txt
    echo VLBI-cwl ended
fi
} |& tee job_output_full.txt
