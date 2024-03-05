---
title: Home
layout: home
nav_order: 1
---
This page documents my [LOFAR containers], very creatively named "Frits' LoFAR Containers" or FLoCs. These containers package a collection of common LOFAR software that is used for imaging science with both Dutch and international array. Pre-built containers are publicly available through a webdav hosted on [SURF]. For instructions on running a pipeline, for example, see [Using the containers](https://tikk3r.github.io/flocs/docs/using-containers.html#pipeline-use)

# Latest containers

{: .warning}
> Pipelines using the genericpipeline framework can _only_ be run with the 3.X container versions that still ship with Python 2. Container versions 4.X and up no longer support this.

[Download v5.0.0 (Py3, Intel Sandy Bridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/flocs_v5.0.0_sandybridge_sandybridge_mkl_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v5.0.0 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v5.0.0_znver2_znver2_aocl_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v3.5 (Py2, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v3.5_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[View recipes on GitHub][LOFAR containers]{: .btn .fs-5 .mb-4 .mb-md-0 }

# Previous containers

## Version 4.X

{: .important}
> Containers labeled `x86-64_generic` are built generically without compiler optimisations in an attempt to allow them to run on a wide variety of machines. The cost of that is that these containers run slower than containers optimised for the specific CPU architecture of your machine or cluster.

[Download v4.5.0 (Py3, Intel Sandy Bridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/flocs_v4.5.0_sandybridge_sandybridge_mkl_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.5.0 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v4.5.0_znver2_znver2_aocl4_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.4.0 (Py3, Intel Sandy Bridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/lofar_sksp_v4.4.0_sandybridge_sandybridge_ddf_mkl_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.4.0 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.4.0_znver2_znver2_aocl4.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.3.1 (Py3, Intel Sandy Bridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/lofar_sksp_v4.3.1_sandybridge_sandybridge_ddf_mkl_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.3.1 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.3.1_znver2_znver2_aocl4.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.3.0 (Py3, X86-64 generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/lofar_sksp_v4.3.1_x86-64_generic_ddf_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.3.0 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.3.0_znver2_znver2_aocl4.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.2.2 (Py3, Intel Sandybridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/lofar_sksp_v4.2.2_sandybridge_sandybridge_ddf_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.2.2 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.2.2_znver2_znver2_aocl4_debug.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.2.1 (Py3, Intel Sandybridge)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/intel/lofar_sksp_v4.2.1_sandybridge_sandybridge_ddf_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.2.1 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.2.1_znver2_znver2_aocl3.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.1.0 (Py3, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v4.1.0_x86-64_generic_ddf_cuda.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Download v4.1.0 (Py3, AMD Zen 2)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/lofar_sksp_v4.1.0_znver2_znver2_aocl3.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.0.2 (Py3, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v4.0.2_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v4.0.1 (Py3, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v4.0.1_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

## Version 3.X

[Download v3.5 (Py2, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v3.5_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[Download v3.4 (Py2, x86-64_generic)](https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif?action=show){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

[LOFAR containers]: https://github.com/tikk3r/flocs
[SURF]: https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/