#!/bin/bash
SIMG=$1
BENCH_DATA=$2
OUTPUT_DIR=$3

RUNDIR=$(mktemp -d -p $TMPDIR)
cd $RUNDIR

IMGNAME=$(basename $SIMG .fits)

echo Copying input data
cp -r $BENCH_DATA/L656064_121_168MHz_uv_pre-cal.concat.ms .
echo Done

echo Imaging starting
time apptainer exec -B $PWD,$TMPDIR,$HOME $SIMG wsclean \
-j 30 \
-verbose \
-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -0.5 \
-parallel-reordering 6 \
-mgain 0.7 \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name benchmark_image_6asec_DI_$IMGNAME \
-scale 1.25arcsec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-parallel-gridding 6 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-gridder wgridder \
-apply-primary-beam \
-use-differential-lofar-beam \
*.ms
echo Done

echo Copying back results
cp *.fits $OUTPUT_DIR
echo Done
