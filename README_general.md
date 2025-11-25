---
title: "README_general"
format: html
editor: DCDM_group3
---

# Project Overview 

This repository contains code and resources developed to process and integrate genotypic and phenotypic data from the International Mouse Phenotyping Consortium (IMPC) into a functional MySQL database and into building an interactive RShiny dashboard for data visualisation.

## Key Features 

Data Integration:

-   Collates raw data from IMPC .csv files.

MySQL Database Design:

-   Designed and normalized schema for efficient storage and querying of multi-realtional genotypic and phenotypic data.

-   Expandable structure to incorporate new phenotypes and analyses.

RShiny Interactive Dashboard:

-   Visualize statistical scores for all phenotypes tested for a selected gene knockout.

-   Explore all knockout genes associated with a specific phenotype (within a parameter group) or with a specific parameter group.

-   Identify groups of genes with similar phenotype scores.

## File Structure

## Pipeline Overview

The project workflow is organized into .. main steps and into categorical folders in the ... directory.

## Requirements 

-   R version

-   DBeaver Version

-   MySQL version

-   R packages:

## Installation 

Database Setup

1.  Install and log into MySQL.
2.  Create the database.
3.  Restore the database:

```{sql connection=}
USE database_name; 
SOURCE dump.sql;

```
