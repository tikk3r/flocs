---
title: WSClean benchmarks
layout: default
nav_order: 2
parent: Benchmarking
---

# WSClean benchmarks

## General container reference
![wsclean benchmark 6 asec]({{ site.baseurl }}/docs/assets/images/wsclean_container_benchmarks_DI_6asec.png)
![wsclean benchmark 1 asec]({{ site.baseurl }}/docs/assets/images/wsclean_container_benchmarks_DI_1asec.png)

## Gridders
Here we compare the performance of gridders available in WSClean. The currently benchmarked gridders are IDG and w-gridder.

### Intermediate resolution imaging
For intermediate resolution imaging a dataset at 4 ch/SB and 4 s time averaging was used. A Gaussian taper to 1.2'' was applied and the job was limited to 30 cores through Slurm. The following WSClean commands were run:

```
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.7 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name image_DI_1asec_idg \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-gridder idg \
-grid-with-beam \
-use-differential-lofar-beam \
*.MS
```

```
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.7 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name image_P240+30_DI_1asec_wgridder \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
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
*.MS

```

![gridder benchmark 1p2 asec]({{ site.baseurl }}/docs/assets/images/benchmark_gridders_1p2asec.png)
