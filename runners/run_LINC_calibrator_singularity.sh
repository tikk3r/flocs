# Update these variables to reflect your environment.
## Location of LINC. This must be a user-writable location for this wrapper script.
## If it does not exist, this script will attempt to clone the LINC repository to the given path.
LINC_DATA_ROOT=/data2/sweijen/Quasar_Anniek/LINC_calibrator/LINC

DATADIR=/data2/sweijen/Quasar_Anniek/3C295_pre/
TMPDIR=$PWD

## WORKDIR is where all the other directories will be stored.
WORKDIR=$(mktemp -d -p "$TMPDIR")
echo $WORKDIR
## Final results will be copied here.
RESULTSDIR=$WORKDIR/results_LINC_calibrator/
## Logs of the various steps will be put here.
LOGSDIR=$WORKDIR/logs_LINC_calibrator/
## Temporary files are stored here.
## The trailing slash is important here.
TMPDIR=$WORKDIR/tmpdir_LINC_calibrator/

SIMG=/net/lofar1/data1/sweijen/software/LOFAR/singularity/lofar_sksp_v4.0.0_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

# Update these variables to tune performance.
## Limit the number of DP3 processes running simultaneously to this amount.
MAX_DP3_PROCS=8

CORES_MACHINE=`nproc`
CORES_CALIBCAL=$(($CORES_MACHINE/$MAX_DP3_PROCS))
CORES_PREDICT=$(($CORES_MACHINE/$MAX_DP3_PROCS))

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
export PYTHONPATH=$LINC_DATA_ROOT/scripts

# Prepare workflow files.
echo Overriding workflow core requirements with user settings.
sed -i "s/coresMin: [0-9]*/coresMin: $CORES_CALIBCAL/" $LINC_DATA_ROOT/steps/ddecal.cwl
sed -i "s/coresMin: [0-9]*/coresMin: $CORES_PREDICT/" $LINC_DATA_ROOT/steps/predict.cwl

# Pass along necessary variables to the container.
export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
export APPTAINERENV_PYTHONPATH=$PYTHONPATH

mkdir -p $RESULTSDIR
mkdir -p $LOGSDIR
mkdir -p $TMPDIR
cd $WORKDIR

singularity exec -B $PWD,/data1,/data2 $SIMG python /data2/sweijen/Quasar_Anniek/create_ms_list.py $DATADIR

echo LINC starting
#time singularity exec -B $PWD,/data1,/data2 $SIMG cwltool --parallel --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json
time singularity exec -B $PWD,/data1,/data2 $SIMG toil-cwl-runner --batchSystem='single_machine' --bypass-file-store --maxCores=12 --preserve-entire-environment --no-container --tmpdir-prefix=$TMPDIR --outdir=$RESULTSDIR --log-dir=$LOGSDIR $LINC_DATA_ROOT/workflows/HBA_calibrator.cwl mslist.json
echo LINC ended
