DROP DATABASE IF EXISTS IMPC_Database;
CREATE DATABASE IMPC_Database;
USE IMPC_Database;
SET SQL_SAFE_UPDATES = 0;
SET GLOBAL local_infile=true;

CREATE TABLE Genes (
    Gene_Accession_ID VARCHAR(50) NOT NULL,
    Gene_symbol VARCHAR(50),
    CONSTRAINT Gene_accession_pk PRIMARY KEY (Gene_Accession_ID)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/clean_merged_output.csv'
IGNORE INTO TABLE Genes
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, Gene_Accession_ID, Gene_symbol, @skip, @skip, @skip, @skip, @skip);

CREATE TABLE Disease_Information(
    DO_Disease_id VARCHAR(50) NOT NULL, 
    DO_Disease_Name VARCHAR(255),
    CONSTRAINT PK_Disease PRIMARY KEY (DO_Disease_id)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_diseases.csv'
IGNORE INTO TABLE Disease_Information
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, DO_Disease_Name, @skip, @skip);

CREATE TABLE PARAMETER_GROUPINGS (
    GROUP_ID INT AUTO_INCREMENT PRIMARY KEY,
    GROUP_NAME VARCHAR(50) NOT NULL UNIQUE 
);

INSERT INTO PARAMETER_GROUPINGS (GROUP_NAME) VALUES
('Weight'), ('Images'), ('Brain');

CREATE TABLE PROCEDURE_INFO (
    procedure_name VARCHAR(255) NOT NULL,
    description TEXT, 
    isMandatory VARCHAR(10),
    CONSTRAINT IMPC_procedure_pk PRIMARY KEY (procedure_name)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_procedures.csv'
IGNORE INTO TABLE PROCEDURE_INFO
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(procedure_name, description, isMandatory, @skip);

CREATE TABLE PARAMETER_DESCRIPTION(
    name TEXT,
    description TEXT,
    parameterId VARCHAR(100),
    GROUP_ID INT,
    CONSTRAINT parameter_description_pk PRIMARY KEY (parameterId),
    CONSTRAINT fk_parameter_group FOREIGN KEY (GROUP_ID) REFERENCES PARAMETER_GROUPINGS(GROUP_ID)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_parameters_final.csv'
IGNORE INTO TABLE PARAMETER_DESCRIPTION
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@skip, name, description, parameterId);

CREATE TABLE PARAMETER_INFO(
    impcParameterOrigID INT NOT NULL,
    parameterId VARCHAR(100),
    CONSTRAINT parameter_info_pk PRIMARY KEY (impcParameterOrigID),
    CONSTRAINT fk_info_to_dict FOREIGN KEY (parameterId) REFERENCES PARAMETER_DESCRIPTION(parameterId)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_parameters_final.csv'
IGNORE INTO TABLE PARAMETER_INFO
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' -- Added '\r' to match the file
IGNORE 1 ROWS
(impcParameterOrigID, @skip, @skip, parameterId );

UPDATE PARAMETER_DESCRIPTION   ######REDO THIS GROUPING BY PARAMETER_ID CODES E.G. IMPC_"XXX"
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Weight')
WHERE name LIKE '%weight%' OR name LIKE '%mass%' OR description LIKE '%weight%';

UPDATE PARAMETER_DESCRIPTION 
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Images')
WHERE name LIKE '%image%' OR name LIKE '%x-ray%' OR description LIKE '%image%';

UPDATE PARAMETER_DESCRIPTION 
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Brain')
WHERE name LIKE '%brain%' OR name LIKE '%head%' OR name LIKE '%cranial%';

CREATE TABLE Phenotype_Analysis (
    analysis_id VARCHAR(50) NOT NULL PRIMARY KEY,
    gene_accession_id VARCHAR(50),
    mouse_life_stage VARCHAR(50),
    mouse_strain VARCHAR(50),
    parameter_id VARCHAR(100),
    parameter_name VARCHAR(255),
    pvalue FLOAT NULL,
    CONSTRAINT Fk_Analysis_to_gene FOREIGN KEY (gene_accession_id) REFERENCES Genes(Gene_Accession_ID),
    CONSTRAINT fk_analysis_to_parameter FOREIGN KEY (parameter_id) REFERENCES PARAMETER_DESCRIPTION(parameterId)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/clean_merged_output.csv'
IGNORE INTO TABLE Phenotype_Analysis
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, @skip, mouse_life_stage, mouse_strain, parameter_id, parameter_name, @temporary_pvalue)
SET pvalue = NULLIF(@temporary_pvalue, 'NA');

####This may be obsolete if achieved in the merge_cleaning script 
UPDATE Phenotype_Analysis
SET parameter_name = 'Platelet count'
WHERE parameter_name = 'Platelets count';

UPDATE Phenotype_Analysis
SET parameter_name = 'Mean cell haemoglobin concentration'
WHERE parameter_name = 'Mean cell hemoglobin concentration';

UPDATE Phenotype_Analysis
SET parameter_name = 'Mean cell volume'
WHERE parameter_name = 'Mean-cell-volume';

UPDATE Phenotype_Analysis
SET parameter_name = 'Mean corpuscular haemoglobin'
WHERE parameter_name IN ('Mean corpuscular hemoglobin', 'Mean-corpuscular-haemoglobin');

CREATE TABLE PROCEDURE_PARAMETER_LINK (
    id INT AUTO_INCREMENT,
    procedure_name VARCHAR(255) NOT NULL,
    impcParameterOrigID INT,
    CONSTRAINT procedure_to_parameter_link_pk PRIMARY KEY (id),
    CONSTRAINT fk_link_to_procedure FOREIGN KEY (procedure_name) REFERENCES PROCEDURE_INFO(procedure_name),
    CONSTRAINT fk_link_to_parameter FOREIGN KEY (impcParameterOrigID) REFERENCES PARAMETER_INFO(impcParameterOrigID)
);

SELECT 
    COUNT(*) AS total_parameters,
    SUM(CASE WHEN ppl.procedure_name IS NULL THEN 1 ELSE 0 END) AS without_procedure,
    ROUND(100.0 * SUM(CASE WHEN ppl.procedure_name IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_null
FROM PARAMETER_DESCRIPTION pd
LEFT JOIN PARAMETER_INFO pi ON pd.parameterId = pi.parameterId
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl ON pi.impcParameterOrigID = ppl.impcParameterOrigID;

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_procedures.csv'
IGNORE INTO TABLE PROCEDURE_PARAMETER_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(procedure_name, @skip, @skip, impcParameterOrigID);

CREATE TABLE OMIM_DISEASE_LINK(
    id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    DO_Disease_id VARCHAR(50),
    OMIM_ID VARCHAR(50) NOT NULL,
    CONSTRAINT Fk_omim FOREIGN KEY (DO_Disease_id) REFERENCES Disease_Information(DO_Disease_id),
    CONSTRAINT unique_omim UNIQUE (DO_Disease_id, OMIM_ID)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_diseases.csv'
IGNORE INTO TABLE OMIM_DISEASE_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, @skipped_column, OMIM_ID, @skipped_column);

CREATE TABLE MOUSE_GENE_DISEASE_LINK(
    id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    DO_Disease_id VARCHAR(50),
    Gene_Accession_ID VARCHAR(50) NOT NULL,
    CONSTRAINT FK_MGI FOREIGN KEY (DO_Disease_id) REFERENCES Disease_Information(DO_Disease_id),
    CONSTRAINT fk_link_to_gene FOREIGN KEY (Gene_Accession_ID) REFERENCES Genes(Gene_Accession_ID),
    CONSTRAINT unique_mgi UNIQUE (DO_Disease_id, Gene_Accession_ID)
);

LOAD DATA LOCAL INFILE '/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_diseases.csv'
IGNORE INTO TABLE MOUSE_GENE_DISEASE_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, @skipped_column, @skipped_omim_column, Gene_Accession_ID);

SELECT DISTINCT g.gene_symbol
FROM IMPC_Database.Phenotype_Analysis pa
JOIN IMPC_Database.Genes g
    ON pa.gene_accession_id = g.Gene_Accession_ID
WHERE pa.parameter_id = 'IMPC_GRS_010_001';

SELECT 
    pi.impcParameterOrigID,
    pd.parameterId AS parameter_id,
    proc.procedure_name,
    proc.description AS procedure_description,
    proc.isMandatory
FROM 
    IMPC_Database.PARAMETER_DESCRIPTION pd
LEFT JOIN 
    IMPC_Database.PARAMETER_INFO pi ON pd.parameterId = pi.parameterId
LEFT JOIN 
    IMPC_Database.PROCEDURE_PARAMETER_LINK ppl ON pi.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN 
    IMPC_Database.PROCEDURE_INFO proc ON ppl.procedure_name = proc.procedure_name
WHERE 
    pd.parameterId = 'HMGULA_OFD_010_001';


SELECT 
    pi.impcParameterOrigID,
    pd.parameterId AS parameter_id,
    proc.procedure_name,
    proc.description AS procedure_description,
    proc.isMandatory
FROM 
    IMPC_Database.PARAMETER_DESCRIPTION pd
LEFT JOIN 
    IMPC_Database.PARAMETER_INFO pi ON pd.parameterId = pi.parameterId
LEFT JOIN 
    IMPC_Database.PROCEDURE_PARAMETER_LINK ppl ON pi.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN 
    IMPC_Database.PROCEDURE_INFO proc ON ppl.procedure_name = proc.procedure_name
Where
pd.parameterId = 'IMPC_GEP_004_002';
create_tables.sql