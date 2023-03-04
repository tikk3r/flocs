#!/usr/bin/bash
#SBATCH -c 6 -t 03:00:00 --job-name=build_container --constraint=amd
# If no root is available the system must offer --fakeroot. Otherwise use sudo.
singularity build --fakeroot --force lofar_sksp_v4.0.2_znver2_znver2_noavx512_aocl_cuda_ddf.sif Singularity.amd_aocl
