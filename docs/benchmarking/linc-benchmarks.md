---
title: LINC benchmarks
layout: default
nav_order: 3
parent: Benchmarking
---

# LINC benchmarks
{: .important}
> For these benchmarks, LINC was run using the runner scripts found [here](https://github.com/tikk3r/flocs/tree/fedora-py3/runners).

This page aims to collect some basic statistics about LINC runtimes on various systems, to provide users a rough idea of how long a run will take. Reported have been obtained from the `real` entry of Linux's `time` command. If nothing is specified, a container built for the target architecture was used.

## LINC Calibrator

|Vendor|CPU|Cores|Threads|Dual CPU?|RAM [GB]|Source|Observation length [min]| Bandwidth [MHz]|Run time|
|---|---|---|---|---|---|---|---|---|
|Intel|Intel(R) Xeon(R) Gold 5220R CPU @ 2.20GHz|48|96|Yes|512|3C 295|480|48|2086m26.453s
|Intel|Intel(R) Xeon(R) Gold 5220R CPU @ 2.20GHz|48|96|Yes|512|3C 295|10|48|257m3.044s


## LINC Target

|Vendor|CPU|Cores|Threads|Dual CPU?|RAM [GB]|Source|Observation length [min]|Bandwidth [MHz]|Run time|
|---|---|---|---|---|---|---|---|---|
|Intel|Intel(R) Xeon(R) Gold 5220R CPU @ 2.20GHz|48|96|Yes|512|3C 295|480|48|1901m22.024s