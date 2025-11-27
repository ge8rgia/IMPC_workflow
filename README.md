
# Project Overview 

This repository contains code developed to process and integrate genotypic and phenotypic data from the International Mouse Phenotyping Consortium (IMPC). This workflow transforms the raw expiremental data into a structured format, stores it in a relational database, (MySQL) provides an interactive dashboard (RShiny) for researchers to explore gene-phenotype association through intituitive data visualisation.

![workflow_pipeline_faster](https://github.com/user-attachments/assets/527fcf19-f970-4077-857b-e09ece99562a)

## Repository Structure
The project is organised into two distinct sibling directories, one which will host data whilst the cloned git repo will contain the code & logic. For steps conducted in R relative paths have been assumed so no configuration of path files should be needed. SQL as it was developed locally will require path configuration according to your machine 
```text
Project_Root/
├── Data_Directory/                <-- Data Storage Directory (in our case Group3/)
│   ├── data/                      <-- Raw experimental CSVs (Auto-sorted)
│   ├── metadata/                  <-- SOPs and Reference files (Auto-sorted)
│   ├── processed_data/            <-- Cleaned CSV outputs
│   └── impc_export.csv/ <-- SQL query export csv for linkage to RShiny
└── IMPC_Workflow/                 <-- Source Code Directory
    ├── 1.Cleaning_Process/        <-- ETL Pipeline (R Scripts)
    │   ├── Format_and_Merge.r
    │   ├── data_cleaning.r
    │   └── metadata_cleaning_hpc.r
    │
    ├── 3.Database/                <-- SQL Schemas & Dump Files
    │   ├── SQL_IMPC_Workflow_FINAL.sql
    │   ├── Collab_request_queries.script.sql
    │   └── database3.dump
    │
    └── 3.RshinyDashboard/         <-- Interactive Visualization using SQL query
        └── Rshiny_IMPC_Workflow_FINAL.R
```
## Key Features 
This pipeline is designed to be reproducible and robust, we require you to execute the components in the following order.

Stage 1:
IMPC_Workflow/1.Cleaning_Process/
These scripts automatically organise the raw directory, merge the non uniform csvs and clean data inconsistences present

Order of Script Execution
1- Format_and_Merge.r: Initalises directory structure, sorts files and merges raw 
   expiremental data.

2. data_cleaning.r: Cleans the data/ files via standardisation procedures
   
3. metadata_cleaning_hpc.r: Cleans metadata and reconciles it with expiremental data to prevent no orphan records for database integration

Run the following commands after unzipping egressed data within your project root and cloning the git repoistory.
cd IMPC_Workflow/1.Cleaning_Process
Rscript Format_and_Merge.r
Rscript data_cleaning.r
Rscript metadata_cleaning_hpc.r

Stage 2:
IMPC_Workflow/2.Database/

The processed data is stored in a relational database to support complex querying. It is designed for scalability in mind through its normalisied structure. As stated initially, load data commands will have to be configured i.e. :"../../Data_Directory/processed_data/clean_merged_data.csv", otherwise a pre-populated database dump is available for quick deployment, with more guidance within its specific directory (2.Database/)

You may query the database with the collaborator queries included in this directory (Signifcant hits section) and export the result to your Project Directory, making sure it adheres to the outlined structure if you wish to load it in and run the RShiny app.

Stage 3: Visualisation via Web Application (RShiny)
The interactive dashboard  allows users to explore the cleaned data, without having to have written the code.
Features

-   Visualize statistical scores for all phenotypes tested for a selected gene knockout.

-   Explore all knockout genes associated with a specific phenotype (within a parameter group) or with a specific parameter group.

-   Identify groups of genes with similar phenotype scores.

To run: Run the cleaning scripts as outlined in Stage 1, export the query result in Stage 2, open Rshiny_IMPC_Workflow_FINAL.R in Rstudio and click "Run App'


## Dependencies & Requirements
R Version: 4.0+
DBeaver Version: 25.2.3+

R packages: tidyverse,shiny, shinydashboard, DT, ggplot2, ComplexHeatmap.

Environment: Supported on Local Machines (Mac/Windows) and HPC environments.

Pathing: All R scripts utilise relative paths (../../Group3), ensuring the code runs immediately upon cloning without modification




