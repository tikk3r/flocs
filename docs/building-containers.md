---
title: Building
layout: default
nav_order: 2
---

# Building containers
Rebuilding containers is necessary if you want to change or add software, or optimise for a specific machine.

{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}
---

The recipes offer customisation options through environment variables near the top. Environment variables that a user may want to modify are summarised in the table below. Other variables should not requrie modification unless there are specific reasons for doing so.

| Variable | Values | Purpose |
|----------|--------|---------|
|`HAS_CUDA`|true/false| Install Nvidia CUDA and link IDG to it if set to `true`. |
|`HAS_MKL`| true/false| Install the Intel Math Kernel Library en link IDG to it if set to `true`.|
|`MARCH`|[GCC compatible architecture](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html)| Passed to GCC's `-march` option to generate code optimised for the specified CPU architecture.|
|`MTUNE`|[GCC compatible architecture](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html)| Passed to GCC's `-mtune` option to optimise code for the specified CPU architecture.|
|`NOAVX512`|true/false| Disables the use of AVX512 instructions if set to `true`. Recommended when building for older or generic hardware on a modern machine, or when building AMD-specific containers on an Intel machine.|
|`CPPSTD`|[C++ standard](https://gcc.gnu.org/projects/cxx-status.html)| Passed to GCC's `-std` option when building C++ code, specifying which C++ standard to use.|


## Building a generic container