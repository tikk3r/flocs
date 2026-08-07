---
title: Automated processing with flocs
layout: default
nav_order: 4
has_children: true
---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

# End-to-end processing of ILT HBA data with flocs

Automated processing of HBA ILT data is offered by [flocs-processing](https://github.com/FLOCSoft/flocs-processing). Where `flocs-runners` provides the interface to running pipelines, `flocs-processing` is the scaffolding to tie it together. Data reduction is coordinated via a dedicated SQLite database that holds information on which observations to process, which pipelines to run for them and all of the related statuses. Orchestration of all the pipelines is handled via Airflow through Directed Acyclic Graphs (DAGs).

The autoPILOT package (https://github.com/LOFAR-VLBI/autoPILOT) needs to be on PYTHONPATH to enable the automatic calibrator assessment.

## Folder setup
Flocs-processing requires three folders to be setup:

* A processing folder -- this is where data is stored while processing
* A data folder -- this is where the input data is found
* An output folder -- this is where finished pipeline outputs are copied to, and searched for in steps that depend on it.

The expected naming directory structure for input data is `<data folder>/<field name>/{calibrator,target}`. Inside the calibrator and target folders, the observations should follow the usual `LXXXXXX` naming scheme. These **must** match the SAS IDs in the database for flocs to be able to find them.

## Database setup
A database for processing is created via `flocs-processing create-database --pipelines linc ddf-pipeline vlbi-delay-widefield <othe options>`. This will create an empty database with the necessary columns for widefield imaging processing. Datasets to process can be added via `flocs-processing add-field`.

## Processing data
To start processing data, Airflow needs to be running for the orchestration. This is handled by `flocs-processing deploy-airflow`. See <insert link> for details about the setup. 

Once `flocs-processing` is complete the processing loop will be automatic, but for now the user must trigger the DAG manually. On the "Dags" tab you should now see the flocs DAGs available. To manually trigger one, click on the name and on the subsequent page use the "Trigger" button in the top right.


