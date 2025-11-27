This directory contains Rscripts responsible for the 1st step of the workflow, it primarily deals
with organising the project directory structure, the merging of  raw data files and cleaning both 
raw expirmental data and associated metadata from the IMPC dataset, we egressed out.

The scripts are designed to use relative paths and assume the following directory hierachy
Here is a comprehensive README.md for your Cleaning Process directory. This documentation explains the execution order, directory structure, and the specific function of each script based on the code contained in this repository.


1. Cleaning & Pre-processing Pipeline
As stated above, this directory contains the R scripts responsible for organizing the raw project structure, merging raw data files, and cleaning both experimental data and metadata for the IMPC dataset.


Directory Structure

```text
Group_Folder/
├── Group3/                     <-- Project Root (Data lives here)
│   ├── data/                   <-- Created automatically after unzipping
│   ├── metadata/               <-- Created automatically after unzipping
│   └── processed_data/         <-- Outputs saved here after running scripts
└── IMPC_Workflow/
    └── 1.Cleaning_Process/     <-- Scripts live here (Current Directory)
        ├── Format_and_Merge.r
        ├── data_cleaning.r
        └── metadata_cleaning_hpc.r
```


#### After collecting your egressed data make sure it is placed at the Project Root layer (e.g. unzip Group3.zip), clone this git repoistroy to begin the pipeline.
#### unzipping your directory should result in the following format: GroupX.zip, GroupX/, clone the repoistory at this level and proceeed with the steps outlined below.





The scripts must be executed in the following order:
1. Format_and_Merge.r : Sets up initial folder structure, detects the Group folder as the root and creates the required subdirectories,before organising them based on this, raw data files go into data/ and pre-defined metadata files go into metadata/
Merges all data/ files into a standardised format and saves this dataframe as an output in processed_data/.

![output](https://github.com/user-attachments/assets/3e8c64ac-c4fe-4171-b5b4-639d08b6d9dc)

3. data_cleaning.r: Standardises this merged data frame according to SOP criteria and outputs
clean_merged_data.csv in processed_data/

4. metadata_cleaning_hpc.r: Cleans the metadata files and reconciles them with expiremental data
produces the following outputs:
processed_data/disease_information_clean.csv
processed_data/IMPC_parameter_clean.csv          
processed_data/IMPC_procedure_cleab.csv

To run the full pipeline, execute the scripts sequentially from IMPC_Workflow/1.Cleaning_Process
1. Rscript Format_and_Merge.r
2. Rscript data_cleaning.r
3. Rscript metadata_cleaning_hpc.r

Deendencies (R packages):
tidyverse, dpylr stringr, readr, tidyr.
