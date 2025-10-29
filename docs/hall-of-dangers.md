---
title: Hall of Dangers
layout: default
nav_order: 99
---

# Hall of dangers
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

This page summarises examples of calibration solutions etc. gone wrong for various pipelines. In general the key plots to look at are those of the calibration solutions. Noisy solutions are problematic and can be indiciative of a variety of issues, such as model incompleteness, certain baselines being starved of signal or the ionosphere being wild.

# LINC output
## LINC Calibrator

LINC Calibrator corrects for systematic effects: an offset between the XX and YY correlations, a bandpass correction and an average clock drift.

### Bad polalign
**Problems:**

* strange wood grain pattern on many core stations
* large spread in values between core stations
* horizontal ripples on CS103 and CS302
* weird banding in CS002
* DE604 and SE607 show no phase structure

![LINC calibrator phases polXX]({{ site.baseurl }}/docs/assets/images/polalign_ph_polXX_bad.png)

### Bad bandpass
**Problems:**

* International station bandpasses are completely wrong shape. They should look similar, to the Dutch ones (but higher values).
* Lots of flagged data in general.

**Notes:**

* This data was taken during a G2 geomagnetic storm, i.e. a bad scenario with probably a very wild/disturbed ionosphere.

![LINC calibrator bandpasses]({{ site.baseurl }}/docs/assets/images/bandpass_time5185634402.00278_L2014928.png)

## LINC Target

LINC Target mainly solves for direction-independent ionospheric effects. The resulting phase solutions should reflect ionospheric behaviour and must therefore appear physical. This means that you expect smooth variations, especially as a function of frequency, that is trackable by eye. If solutions get noisy, discrete or you can no longer see a smooth pattern by eye that are indications of problems and depending on their severity demand further inspection of your data before proceeding to further more complicated pipelines. In general it is useful to think of it as any problem you introduce at a given step being *uncorrectable* in later steps.


### 3C295

Extremely bright 3C source that is just resolved on the longest Dutch baselines.

**Problems:**

* extreme phase wrapping-like behaviour on remote stationsnoisy
* noisy corners on core stations
* certain bad times (vertical noise stripes)
* Poldif plot showing XX-YY displays noise

**Causes:** TGSS model does not have enough resolution to represent structure seen by the furthest remotes.

![LINC target phases polXX 3C295]({{ site.baseurl }}/docs/assets/images/3C295_ph_polXX.png)
![LINC target phases poldif 3C295]({{ site.baseurl }}/docs/assets/images/3C295_ph_poldif.png)

### GalField3

Galactic plane field with complex, large-scale diffuse emission.

**Problems:**

* exremely noisy, descretised solutions on many remote stations, basically wiping out any signal
* complex structure core station solutions
* XX-YY polarisation difference extremely noisy

**Causes:** model incompleteness TGSS model does not contain this scale of diffuse emission.

![LINC target phases polXX GalField3]({{ site.baseurl }}/docs/assets/images/GalField3_ph_polXX_before.png)
![LINC target phases poldif GalField3]({{ site.baseurl }}/docs/assets/images/GalField3_ph_poldif_before.png)

### L801462

**Problems:**

* wild time fluctuations on core stations, indicative of a wild ionosphere
* extreme phase wrapping-like behaviour on remote stations.

**Causes:** very bad ionosphere and possible model incompleteness.

![LINC target phases polXX L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_polXX.png)
![LINC target phases poldif L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_poldif.png)


## VLBI delay calibration

### ILTJ110224.07+574725.2

Bright ~1 Jy point-like source in LockmanC. A reasonably simple field and calm ionospheric conditions.

**Problems**

* Oil stain-like patterns in the phase solutions instead of nice continues wrapping

**Causes:**

* in this case: bad _LINC Target_ solutions due to using the chunked 2 MHz calibration strategy. N.B. that this happens even when using the highly complete LOTSS sky model.
* in general: another possibility is a too high value for the smoothness constraint.

**Solution:** run LINC Target with `num_SB_per_group=-1` and `calib_nchan=1` such that the smoothness constraint can do its work.

![delay solutions oil stains]({{ site.baseurl }}/docs/assets/images/ILTJ110224.07+574725.2_scalarphase1.png)


### Oversmoothing of phase solutions

**Problems**

* Strange patterins en FR606,SE607

**Causes**

* Smoothness constraint was set too high w.r.t. the speed of phase wrapping. Solving with 0 smoothness reveals that the ionosphere is not suddenly calmer, but that phases wrap quickly.

![delay solutions oil stains]({{ site.baseurl }}/docs/assets/images/scalarphase1_selfcalcycle000dir\[MODEL_DATA\]_oversmoothed.png)
![delay solutions oil stains]({{ site.baseurl }}/docs/assets/images/scalarphase1_selfcalcycle000dir\[MODEL_DATA\].png)
