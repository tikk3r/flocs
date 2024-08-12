#!/bin/bash
OBSID=$(basename $1)
QUEUE=dine2
ACCOUNT=do011
CALSOLS=/path/to/cal_solutions.h5
OUTPUT_DIR=/path/to/output/

sbatch <<EOT
#!/bin/bash
#SBATCH -t 24:00:00 -c 32 --job-name=LINC_Target_$OBSID -p $QUEUE -A $ACCOUNT

TMPDIR=/snap8/scratch/do011/dc-swei1/temp_lockman/
export TMPDIR

export WORKDIR=\$(mktemp -d -p "\$TMPDIR")
cd \$WORKDIR

SOFTWARE_ROOT=/cosma/apps/do011/dc-swei1/
export SOFTWARE_ROOT
CONTAINER=\$SOFTWARE_ROOT/containers/flocs_v5.2.0beta_cascadelake_cascadelake_f38.sif
FLOCS_ROOT=\$SOFTWARE_ROOT/flocs
export FLOCS_ROOT
LINC_ROOT=\$SOFTWARE_ROOT/LINC
export LINC_ROOT

DATA_DIR=$1

bash \$FLOCS_ROOT/runners/run_LINC_target_HBA.sh -d \$DATA_DIR -s \$CONTAINER -b /cosma8,/cosma/apps -r \$WORKDIR -l \$LINC_ROOT -f \$FLOCS_ROOT -c \$CALSOLS

cp -r \$TMPDIR/\$OBSID_LINC_target \$OUTPUT_DIR/
EOT
