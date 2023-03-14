---
title: Home
layout: home
nav_order: 1
---
This page documents my [LOFAR containers], very creatively named "Frits' LoFAR Containers" or FLoCs. These containers package a collection of common LOFAR software that is used for imaging science with both Dutch and international array. Pre built containers are publicly available through a webdav hosted on [SURF].

# Latest containers

{: .important}
> These containers are built generically without compiler optimisations in an attempt to allow them to run on a wide variety of machines. The cost of that is that containers labeled `x86-64_generic` run slower than containers optimised for the specific CPU architecture of your machine or cluster.

{: .warning}
> Pipelines using the genericpipeline framework can _only_ be run with the 3.X container versions that still ship with Python 2. Container versions 4.X and up no longer support this.

[Download v3.5 (Py2, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v3.5_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.0.2 (Py3, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v4.0.2_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View recipes on GitHub][LOFAR containers]{: .btn .fs-5 .mb-4 .mb-md-0 }

# Previous containers
[Download v3.4 (Py2, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.0.1 (Py3, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v4.0.1_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[LOFAR containers]: https://github.com/tikk3r/flocs
[SURF]: https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/
