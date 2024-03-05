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
### 3C295

**Problems:**

* extreme phase wrapping-like behaviour on remote stationsnoisy
* noisy corners on core stations
* certain bad times (vertical noise stripes)
* Poldif plot showing XX-YY displays noise

**Causes:** TGSS model does not have enough resolution to represent structure seen by the furthest remotes.

![LINC target phases polXX 3C295]({{ site.baseurl }}/docs/assets/images/3C295_ph_polXX.png)
![LINC target phases poldif 3C295]({{ site.baseurl }}/docs/assets/images/3C295_ph_poldif.png)

### L801462

**Problems:**

* wild time fluctuations on core stations, indicative of a wild ionosphere
* extreme phase wrapping-like behaviour on remote stations.

**Causes:** very bad ionosphere and possible model incompleteness.

![LINC target phases polXX L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_polXX.png)
![LINC target phases poldif L801462]({{ site.baseurl }}/docs/assets/images/L801462_ph_poldif.png)
