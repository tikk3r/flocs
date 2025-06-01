#!/bin/bash
OBSID=$(basename $1)
QUEUE=dine2
ACCOUNT=do011
CALSOLS=/path/to/cal_solutions.h5
OUTPUT_DIR=/path/to/output/

SOFTWARE_ROOT=/cosma/apps/do011/dc-swei1/
export SOFTWARE_ROOT
CONTAINER=$SOFTWARE_ROOT/containers/flocs_v5.2.0beta_cascadelake_cascadelake_f38.sif
FLOCS_ROOT=$SOFTWARE_ROOT/flocs
export FLOCS_ROOT
LINC_ROOT=$SOFTWARE_ROOT/LINC
export LINC_ROOT

TEMPSTUFF=$(mktemp -d -p $PWD --suffix _$OBSID)
cd $TEMPSTUFF

# Find the first Measurement Set
pattern="$1/*.MS"
files=( $pattern )
ms="${files[0]}"  # printf is safer!

# Download RMextract solutions
cp $CALSOLS .
ACTUAL_CALSOLS=$TEMPSTUFF/$(basename $CALSOLS)

mkdir IONEX
apptainer exec -B /snap8,/cosma8,/cosma/apps $CONTAINER $LINC_ROOT/scripts/createRMh5parm.py --ionexpath $PWD/IONEX --solsetName=target --server='http://ftp.aiub.unibe.ch/CODE' $ms $ACTUAL_CALSOLS

# Obtain a starting skymodel
SKYMODEL=$(realpath skymodel_$OBSID_target.skymodel)
apptainer exec -B /snap8,/cosma8,/cosma/apps $CONTAINER $LINC_ROOT/scripts/download_skymodel_target.py $ms $SKYMODEL

sbatch <<EOT
#!/bin/bash
#SBATCH -t 24:00:00 -c 32 --job-name=LINC_Target_$OBSID -p $QUEUE -A $ACCOUNT

TMPDIR=/snap8/scratch/do011/dc-swei1/temp_lockman/
export TMPDIR

export WORKDIR=\$(mktemp -d -p "\$TMPDIR")
cd \$WORKDIR

SOFTWARE_ROOT=$SOFTWARE_ROOT
export SOFTWARE_ROOT
CONTAINER=$CONTAINER
FLOCS_ROOT=\$SOFTWARE_ROOT/flocs
export FLOCS_ROOT
LINC_ROOT=\$SOFTWARE_ROOT/LINC
export LINC_ROOT

DATA_DIR=$1

bash \$FLOCS_ROOT/runners/run_LINC_target_HBA.sh -d \$DATA_DIR -s \$CONTAINER -b /cosma8,/cosma/apps -r \$WORKDIR -l \$LINC_ROOT -f \$FLOCS_ROOT -c $ACTUAL_CALSOLS -t $SKYMODEL -e"--selfcal=True --gsmcal_step=scalarphase --make_structure_plot=False"

cp -r \$WORKDIR/\${OBSID}_LINC_target \$OUTPUT_DIR/
EOT
