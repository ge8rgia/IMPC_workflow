#Setup
CREATE DATABASE IMPC_Database;
USE IMPC_Database;



#Creating tables
CREATE TABLE Phenotype_Analysis (
  analysis_id  VARCHAR(25)  NOT NULL PRIMARY KEY,
  gene_accession_id VARCHAR(15),
  gene_symbol VARCHAR(15),
  mouse_life_stage VARCHAR(25),
 mouse_strain  VARCHAR(10),
  parameter_id VARCHAR(25),
  parameter_name VARCHAR(100),
  pvalue  FLOAT
);


#If loading data is disabled for local and client side 
show global variables like 'local_infile';
set global local_infile=true;


LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_merged_output.csv'
INTO TABLE Phenotype_Analysis
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, gene_symbol, mouse_life_stage,  mouse_strain ,parameter_id, parameter_name, pvalue);

