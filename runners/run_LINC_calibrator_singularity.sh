# Update these variables to reflect your environment.
# Once everything is set, launch the pipeline with `bash run_LINC_calibrator_singularity.sh`
TMPDIR=$PWD
## WORKDIR is where all the other directories will be stored.
WORKDIR=$(mktemp -d -p "$TMPDIR")
echo $WORKDIR
## Location of LINC. This must be a user-writable location for this wrapper script.
## If it does not exist, this script will attempt to clone the LINC repository _to_ (not in) the given path.
LINC_DATA_ROOT=$WORKDIR/LINC

# Path to the folder where the .MS files are stored.
DATADIR=/data2/sweijen/Quasar_Anniek/3C295_pre/

# Container settings
SIMG=/data1/sweijen/losototest/lofar_sksp_v4.0.0_x86-64_generic_ddf_losoto.sif
# Add any directory that should be accessible during the run here as a comma-separated list.
BINDPATHS=/data1,/data2,$PWD

## Final results will be copied here.
RESULTSDIR=$WORKDIR/results_LINC_calibrator/
## Logs of the various steps will be put here.
LOGSDIR=$WORKDIR/logs_LINC_calibrator/
## Temporary files are stored here.
## The trailing slash is important here.
TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/

#
# Do not update below this line
#
export LINC_DATA_ROOT
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

# Prepare workflow files.
echo "Overriding rfistrategies with Lua >5.3 compatible ones from AOFlagger repository"
wget https://gitlab.com/aroffringa/aoflagger/-/raw/master/data/strategies/lofar-default.lua -O $LINC_DATA_ROOT/rfistrategies/lofar-default.lua

echo Making sure all scripts are executable
chmod 755 $LINC_DATA_ROOT/scripts/*.py

echo Making sure all shebang lines use /usr/bin/env python instead of /usr/bin/env
for f in $LINC_DATA_ROOT/scripts/*.py; do
    sed -i "s?\#\!/usr/bin/python?\#\!/usr/bin/env python?" $f
done

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

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

wget --no-http-keep-alive https://raw.githubusercontent.com/tikk3r/flocs/fedora-py3/runners/create_ms_list.py
singularity exec -B $PWD,$BINDPATHS $SIMG python create_ms_list.py $DATADIR

echo LINC starting
echo export PYTHONPATH=\$LINC_DATA_ROOT/scripts:\$PYTHONPATH > tmprunner.sh
echo 'cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json' >> tmprunner.sh
(time singularity exec -B $PWD,$BINDPATHS $SIMG bash tmprunner.sh 2>&1) | tee $WORKDIR/job_output.txt
echo LINC ended
