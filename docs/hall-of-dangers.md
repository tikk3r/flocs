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

## LINC Target

LINC Target mainly solves for direction-independent ionospheric effects. The resulting phase solutions should reflect ionospheric behaviour and must therefore appear physical. This means that you expect smooth variations, especially as a function of frequency, that is trackable by eye. If solutions get noisy, discrete or you can no longer see a smooth pattern by eye that are indications of problems and depending on their severity demand further inspection of your data before proceeding to further more complicated pipelines. In general it is useful to think of it as any problem you introduce at a given step being *uncorrectable* in later steps.


### 3C295

Extremely bright 3C source that is just resolved on the longest Dutch baselines.

**Problems:**

* exremely noisy, descretised solutions on many remote stations, basically wiping out any signal
* complex structure core station solutions
* XX-YY polarisation difference extremely noisy

**Causes:** model incompleteness TGSS model does not contain this scale of diffuse emission.

![LINC target phases polXX GalField3]({{ site.baseurl }}/docs/assets/images/GalField3_ph_polXX_before.png)
![LINC target phases poldif GalField3]({{ site.baseurl }}/docs/assets/images/GalField3_ph_poldif_before.png)

### GalField3

Galactic plane field with complex, large-scale diffuse emission.

**Problems:**

* extreme phase wrapping-like behaviour on remote stationsnoisy
* noisy corners on core stations
* certain bad times (vertical noise stripes)
* Poldif plot showing XX-YY displays noise

**Causes:** TGSS model does not have enough resolution to represent structure seen by the furthest remotes.

### L801462

**Problems:**

* wild time fluctuations on core stations, indicative of a wild ionosphere
* extreme phase wrapping-like behaviour on remote stations.

**Causes:** very bad ionosphere and possible model incompleteness.

![LINC target phases polXX L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_polXX.png)
![LINC target phases poldif L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_poldif.png)
