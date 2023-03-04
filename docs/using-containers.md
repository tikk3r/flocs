---
title: Using the containers
layout: default
nav_order: 3
---

# Using containers
{: .no_toc}
This page describes basic usage of the LOFAR containers. For more detailed information about Apptainer in general, see the [Apptainer documentation](https://apptainer.org/docs/user/main/index.html).

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important}
> Directories that need to be accessible should be bound to the container by passing `--bind <dir1>,<dir2>,<dir3>` or `-B <dir1>,<dir2>,<dir3>` to either `apptainer shell` or `apptainer exec`. This directory binding is recursive.

{: .important}
> Environment variables that need to be accessible inside the container should either be set _after_ entering the container or set by using the `APPTAINERENV_` prefix _before_ entering the container. For example, defining `APPTAINERENV_MYVAR` will define `MYVAR` inside the container.
>
> If you need to add entries to PATH, this can be done by defining `APPTAINERENV_PREPEND_PATH` or `APPTAINERENV_APPEND_PATH` to, respecitvely, prepend or append values to `PATH`.

{: .warning}
> Pay attention to environmental settings that get passed to the container. Mixing (too much of) the host environment with the container environment can result in unexpected behaviour. Especially `PYTHONPATH` can wreak havoc if inherited from the host system. In a worst case scenario `--cleanenv` or `-c` can be used to clean the host environment before entering the container.

## Interactive use
The containers can act as your normal shell for interactive data reduction. To do so, use

```bash
apptainer shell <container>
```
This will provide a Bash shell with the software and Python environment loaded.

## Non-interactive use
Software can also be directly executed from the container. This is useful when interactive processing is not available or cumbersome, such as on clusters or for bulk processing. To directly execute something in the container, use

```bash
apptainer exec <container> <command> <arguments>
```
For example, compressing a Measurement Set with dysco using DP3 would be done as

```bash
apptainer exec <container> DP3 msin=input.ms msout=output.ms msout.storagemanager=dysco steps=[]
```
It is not restricted to individual commands. Pipelines or bash scripts that execute multiple commands can also be run this way.