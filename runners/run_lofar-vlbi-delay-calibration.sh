#!/usr/bin/env bash
{
echo "=============================="
echo "===    VLBI-cwl Runner     ==="
echo "===   Delay-Calibration    ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
HELP="$(basename $0) [-s <container path>] [-b <container bindpaths>] [-l <user-defined LINC>] [-v <user-defined VLBI-cwl] [-r <running directory>] [-e<options for create_ms_list.py>] -d <data path> -c <LINC solutions>"
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
        c) TARGETSOLS="$OPTARG"
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

if [[ ! -f $TARGETSOLS ]]; then
    echo "Calibrator solutions $TARGETSOLS do not exist or are not accessible!"
    exit 4
else
    export DATADIR=$(readlink -f $DATADIR)
    export TARGETSOLS=$(readlink -f $TARGETSOLS)
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
    echo "No container specified."

    pattern="${DATADIR}/*.MS"
    files=( $pattern )
    ms="${files[0]}"  # printf is safer!
    wget https://raw.githubusercontent.com/LOFAR-VLBI/lofar-vlbi-pipeline/refs/heads/master/plot_field.py
    python plot_field.py --MS $ms

    export PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts:$PATH
    git clone https://github.com/tikk3r/flocs.git

    python flocs/runners/create_ms_list.py VLBI delay-calibration --solset=$TARGETSOLS --configfile=$VLBI_DATA_ROOT/facetselfcal_config.txt --h5merger=$LOFAR_HELPERS_ROOT --selfcal=$FACETSELFCAL_ROOT --delay_calibrator=delay_calibrators.csv --linc=$LINC_DATA_ROOT $EXTRAOPTS $DATADIR

    echo VLBI-cwl starting
    # Switch to a non-GUI backend to avoid plotting issues.
    echo export MPLBACKEND='Agg' > jobrunner.sh
    echo export PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts:$PATH >> jobrunner.sh
    echo export PYTHONPATH=\$VLBI_DATA_ROOT/scripts:\$LINC_DATA_ROOT/scripts:\$PYTHONPATH >> jobrunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $VLBI_DATA_ROOT/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json 2>&1' >> jobrunner.sh
    (time bash jobrunner.sh) |& tee $WORKDIR/job_output_vlbi-cwl_delay-calibration.txt
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
    wget https://raw.githubusercontent.com/LOFAR-VLBI/lofar-vlbi-pipeline/refs/heads/master/plot_field.py
    singularity exec -B $PWD,$BINDPATHS $SIMG python plot_field.py --MS $ms

    git clone https://github.com/tikk3r/flocs.git

    singularity exec -B $PWD,$BINDPATHS $SIMG python flocs/runners/create_ms_list.py VLBI delay-calibration --solset=$TARGETSOLS --configfile=$VLBI_DATA_ROOT/facetselfcal_config.txt --h5merger=$LOFAR_HELPERS_ROOT --selfcal=$FACETSELFCAL_ROOT --delay_calibrator=delay_calibrators.csv --linc=$LINC_DATA_ROOT $EXTRAOPTS $DATADIR

    echo VLBI-cwl starting
    # Switch to a non-GUI backend to avoid plotting issues.
    echo export MPLBACKEND='Agg' > jobrunner.sh
    echo export PYTHONPATH=\$VLBI_DATA_ROOT/scripts:\$LINC_DATA_ROOT/scripts:\$PYTHONPATH >> jobrunner.sh
    echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $VLBI_DATA_ROOT/workflows/delay-calibration.cwl mslist_VLBI_delay_calibration.json 2>&1' >> jobrunner.sh
    (time singularity exec -B $PWD,$BINDPATHS $SIMG bash jobrunner.sh) |& tee $WORKDIR/job_output_vlbi-cwl_delay-calibration.txt
    echo VLBI-cwl ended
fi
echo Cleaning up...
echo == Deleting LOFAR-VLBI tmpdir..
rm -rf $WORKDIR/tmpdir_VLBI_CWL/

echo == Moving results...
FINALDIR=$(dirname $WORKDIR)
pattern="${DATADIR}/*.MS"
files=( $pattern )
ms="${files[0]}"  # printf is safer!
obsid=$(echo $(basename $ms) | awk -F'_' '{print $1}')
mv "$WORKDIR" "$FINALDIR/${obsid}_LOFAR-VLBI_Delay-Calibration"

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
