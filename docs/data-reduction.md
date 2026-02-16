---
title: Data reduction with flocs
layout: default
nav_order: 4
---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


# Direction-independent calibration
## LINC Calibrator
In its most basic form, the HBA calibrator pipeline can be executed as follows:

```bash
flocs-run linc calibrator </folder/with/mses/>
```

The `--save-raw-solutions` option may be of interest if you want to also obtain the h5parms from which the systematic effects were derived. This can be useful to investigate issues if the solutions are not as expected. When a run has finised, go to the `inspection` folder and inspect the following main outputs carefully:

* `polalign.png`: corrects a frequency-dependent offset between XX and YY.
* `bandpass_time<number>.png`: shows the derived bandpasses for all stations. These should look like the usualy HBA shape. If too many stations are missing, high fractions are flagged or the shapes look off consider trying the second calibrator scan.
* `clock.png`: corrects a median clock offsets between stations. Core stations are on the same clock and thus should not show an offset. Its counterpart `tec.png` can also be inspected, as these corrections are derived via clock-TEC separation on the phases.

Be relatively critical of these plots as they can save you from surprises later on. For example, if many stations important to your science case get flagged in these corrections, it is not worth continuing (e.g. losing many international stations for a long baseline project).

## LINC Target
The target pipeline is executed via

```bash
flocs-run linc target --cal-solutions </path/to/calibrator/cal_solutions.h5> </folder/with/mses/>
```

For VLBI data reduction, you want to use the `--output-fullres-data` option (this may become default later). The other parameter of interest is `--min-unflagged-fraction`, which sets the minimum fraction of data that should be left after flagging and concatenating in 2 MHz chunks for LINC to keep it. The default value of LINC is 50%, which can lead to a lot of data being rejected, so I tend to put this to `0.05`. After a successful run, carefully inspect at least

* `ph_polXX.png`. `ph_polYY.png` and `ph_poldiff.png`.

These plots show the phase solutions for XX and YY, and the difference between the two. Good solutions behave well as function of both time and frequence. A rule of thumb is whether you can follow them by eye. Core stations should be quite flat as function of frequency and not show wrapping behaviour. If you see core stations with completely horizontal, quickly wrapping phases then LINC failed to identify this as a bad station and it should be flagged. Remote stations shoudl show smooth phase variations in the frequency direction.

The `poldiff` plot shows XX-YY, which can more easily show adverse effects at play. Look out for starnge patters or noisy solutions in these.

## Example runs
An example of reducing data from on a Slurm managed cluster will look something like this:

```bash
flocs-run linc calibrator --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount </folder/with/calibrator_mses/>
flocs-run linc target --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount --cal_solutions </path/to/calibrator/cal_solutions.h5> </folder/with/target_mses/>
```

When a LINC run finishes a final copy named e.g. `LINC_calibrator_<date>` should be created in the directory where the run was started, or in the specified `--outdir`.
