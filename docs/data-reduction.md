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

The `poldiff` plot shows XX-YY, which can more easily show adverse effects at play. Look out for strange patterns or noisy solutions in these.

# Direction-dependent calibration
## Dutch array DD calibration with DDF-pipeline

The DDF-pipeline is the pipeline used for LoTSS. Flocs does nothing special when running this pipeline apart from just wrapping it in the ecosystem. This makes it a little bit easier to submit it to e.g. a Slurm queue. Call it on the averaged NL-baseline-only output of LINC target (`*pre-cal.ms`):

```bash
flocs-run ddf-pipeline --config-file <ddf config> /path/to/LINC_target*/results_LINC_target/
```

The usual Slurm arguments are supported. You can find example configuration files in the DDF-pipeline repository: https://github.com/mhardcastle/ddf-pipeline/tree/master/examples

# Long baseline calibration
## VLBI delay calibration
A succseful run with flocs will have left a `LINC_target_*` folder where the * will be the SAS ID processed, date and time of the run. Assuming you ran LINC Target with `--output-fullres-data`, the delay calibration can be run as follows:

```bash
lofar-vlbi-plot --MS <folder/with/target/mses/*SB005_uv.MS>
flocs-run vlbi delay-calibration --image-catalogue lotss_catalogue.csv --delay-calibrator delay_calibrators.csv --ms-suffix dp3concat LINC_target*/results_LINC_target/results
```

The MS passed to lofar-vlbi-plot does not matter much, as long as it has the phase centre of your observation. It will generate a catalogue with bright (S > 10 mJy) LoTSS sources as `image_catalogue.csv` and delay calibrator candidates as `delay_calibrators.csv`. If your field is not covered by LBCS you will have to manually make and provide a `delay_calibrators.csv` with your sources of choice. The pipleine will then phaseshift to the first delay calibrator candidate and perform the initial calibration of the international stations.

Inspect the resulting images and calibration solutions carefully. Anything majorly wrong here is generally not fixable from this point on. Inspect the final images for remaining artefacts (e.g. spoke or ring patterns), make sure the noise level is nominal (below 100 uJy/b for a typical 8-hour observation) and make sure the solutions look good and not exhibit strange patterns or lots of noise.

## VLBI direction-dependent calibration: single science target
Upon successful delay calibration the results should contain an h5parm along the lines of `merged*linearfulljones*.h5`. This is used to run the direction-dependent calibration. If you let the pipeline apply the solutions via `--apply-delay-solutions`, the results should contain calibrated MSes again. Flocs disables this by default so you have an opportunity to check the delay calibration solutions before committing to them being applied to data. Next you can create a CSV file called e.g. `target.csv`. This will need at least the columns `Source_id,RA,DEC,Total_flux` and should contain the sources you want to calibrate. You also need to download the neural network that is used for image validation (put it somewhere permanent and you only have to do this once). A dd-calibration for a single target then looks something like the following:

```bash
download_NN --cache_directory /path/to/nn_cache
flocs-run vlbi dd-calibration --peak-flux-cut 0.0 --phasediff-score 10.0 --model-cache /path/to/nn_cache --source-catalogue target.csv --delay-calibrator delay_calibrators.csv --delay-slset /path/to/merged*linearfulljones*.h5 --ms-suffix dp3concat LINC_target*/results_LINC_target/results
```

Here we disable any pre selection on peak intensity or ``phasediff score'' (a proxy for calibratability). If you want the pipeline to reject sources based on this remove them and leave them at the default. If you enabled automatic application of the delay solutions, pass the MSes from the delay calibration instead.

# Example runs
An example of reducing data from on a Slurm managed cluster will look something like this:

```bash
flocs-run linc calibrator --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount </folder/with/calibrator_mses/>
flocs-run linc target --runner toil --scheduler slurm --slurm-time 24:00:00 --slurm-queue myqueue --slurm-account myaccount --cal_solutions </path/to/calibrator/cal_solutions.h5> </folder/with/target_mses/>
flocs-run ddf-pipeline --scheduler slurm --slurm-time 72:00:00 --slurm-queue myqueue --slurm-account myaccount --config-file </path/to/ddf/config.cfg> </folder/with/linc/target/results/>
```

When a LINC run finishes a final copy named e.g. `LINC_calibrator_<date>` should be created in the directory where the run was started, or in the specified `--outdir`. This holds for all pipelines.
