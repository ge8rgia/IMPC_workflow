# IMPC Workflow - RShiny App

This directory contains the script and data used to generate and execute the RShiny App.

### Rshiny_IMPC_Workflow_FINAL.R
This is the complete executable R script used to generate the interactive web app.

The script is only executable locally, it is not publicly available.  

Within this interactive app there are 4 main tabs:
* Explore via Gene Knockout
  - Table
  - Manhattan Plot
* Explore via Phenotype
  - Table
  - Bar Plot
  - QQ Plot
* Gene Clusters - Heatmap
* Gene Clusters - K groups
  - Gene cluster groups
  - Clustree

The user can interact with this app to visualise the following:
1. Select a particular knockout mouse and visualise the statistical scores of all phenotypes tested, including visualising the phenotypes significantly affected by the gene knockout
   - Tab = Explore via Gene Knockout
2. Visualise the statistical scores of all knockout mice for a selected phenotype
   - Tab = Explore via Phenotype
3. Visualise clusters of genes with similar phenotype scores
   - Tabs = Gene Clusters - Heatmap, Gene Clusters - K groups

##### R Version: 4.5.1 (2025-06-13)
##### Required packages: shiny, DT, dplyr, ggplot2, ComplexHeatmap, tidyr, clustree

### impc_export.csv
This is the input file required for the app to run.

The table was generated using an SQL query run in the sql/SQL_IMPC_Workflow_QUERIES.sql file titled:

Query the dataset for information including parameter_name

Input the path to the  file in line 15 of the script as follows:
```r
rshinydata <- read.csv("<path_to_file>/impc_export.csv", stringsAsFactors = FALSE)
```
