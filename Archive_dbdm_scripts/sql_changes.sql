# IMPC_SQL_Workflow_v3

DROP DATABASE IF EXISTS IMPC_Database;
CREATE DATABASE IMPC_Database;
USE IMPC_Database;
SET SQL_SAFE_UPDATES = 0;
SET GLOBAL local_infile=true;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

CREATE TABLE Genes (
    Gene_Accession_ID VARCHAR(50) NOT NULL,
    Gene_symbol VARCHAR(50),
    CONSTRAINT Gene_accession_pk PRIMARY KEY (Gene_Accession_ID)
);

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_merged_output.csv'
IGNORE INTO TABLE IMPC_Database.Genes
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

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_diseases.csv'
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

# Add parameter groupings
INSERT INTO IMPC_Database.PARAMETER_GROUPINGS (GROUP_NAME) VALUES
('Weight'), ('Images'), ('Brain'), ('Eye Morphology'), ('Hematology'), ('CBC Chemistry'), ('Morphology/Development'), ('Activity/Movement'), ('Immunology'), ('Echocardiography');


CREATE TABLE PROCEDURE_INFO (
    procedure_name VARCHAR(255) NOT NULL,
    description TEXT, 
    isMandatory VARCHAR(10),
    CONSTRAINT IMPC_procedure_pk PRIMARY KEY (procedure_name)
);

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_procedures.csv'
IGNORE INTO TABLE PROCEDURE_INFO
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(procedure_name, description, isMandatory, @skip);

CREATE TABLE PARAMETER_DESCRIPTION(
    parameter_name TEXT,      ## Changed from name for specificity
    description TEXT,         
    parameterId VARCHAR(100),
    GROUP_ID INT,
    CONSTRAINT parameter_description_pk PRIMARY KEY (parameterId),
    CONSTRAINT fk_parameter_group FOREIGN KEY (GROUP_ID) REFERENCES PARAMETER_GROUPINGS(GROUP_ID)
);

## Why is impcParameterOrigId in this table (refer to diagram, not used and present in later links)
## Need to add a column to PARAMETER_DESCRIPTION 
## Left join from PROCEDURE_INFO table
## procedure_name needs to be present to correctly label the parameter 

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_parameters.csv'
IGNORE INTO TABLE PARAMETER_DESCRIPTION
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' #convert to \n after data cleaning script made
IGNORE 1 ROWS
(@skip, parameter_name, description, parameterId);

CREATE TABLE PARAMETER_INFO(
    impcParameterOrigID INT NOT NULL,
    parameterId VARCHAR(100),
    CONSTRAINT parameter_info_pk PRIMARY KEY (impcParameterOrigID),
    CONSTRAINT fk_info_to_dict FOREIGN KEY (parameterId) REFERENCES PARAMETER_DESCRIPTION(parameterId)
);

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_parameters.csv'
IGNORE INTO TABLE PARAMETER_INFO
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(impcParameterOrigID, @skip, @skip, parameterId );

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

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_merged_output.csv'
IGNORE INTO TABLE Phenotype_Analysis
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, @skip, mouse_life_stage, mouse_strain, parameter_id, parameter_name, @temporary_pvalue)
SET pvalue = NULLIF(@temporary_pvalue, 'NA');

# To be removed after getting the final data cleaning file
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

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_procedures.csv'
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

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_diseases.csv'
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

LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/data_cleaned/cleaned_diseases.csv'
IGNORE INTO TABLE MOUSE_GENE_DISEASE_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, @skipped_column, @skipped_omim_column, Gene_Accession_ID);


## Add GROUP_IDs
INSERT INTO PARAMETER_DESCRIPTION (procedure_name)
SELECT DISTINCT
	p.parameter_id,
	p.procedure_name
FROM PROCEDURE_INFO p
LEFT JOIN PARAMETER_INFO d
	   ON p.procedure_name = d.impcParameterOrigID
ORDER BY p.parameter_id;
    

# Query so parameter_id is matched with the parameter_name and respective procedure_name.
INSERT INTO IMPC_Workflow_v2.Group_information (parameter_id, parameter_name, procedure_name)
SELECT DISTINCT
    pi.parameter_id,
    pi.parameter_name,
    p.procedure_name
FROM IMPC_Workflow_v2.Parameter_information pi
LEFT JOIN IMPC_Workflow_v2.IMPC_parameter_description d
       ON pi.parameter_id = d.parameter_id
LEFT JOIN IMPC_Workflow_v2.IMPC_procedure p
       ON d.procedure_name = p.procedure_name
ORDER BY pi.parameter_id;



# Weight
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Weight')
WHERE
    (
        LOWER(parameter_name) LIKE '%mass%' OR
        LOWER(procedure_name) LIKE '%mass%'
    )
    OR (
        (LOWER(parameter_name) LIKE '%weight%' OR
         LOWER(procedure_name) LIKE '%weight%')
        AND LOWER(parameter_name) NOT LIKE '%against body weight%'
        AND LOWER(procedure_name) NOT LIKE '%against body weight%'
    )
    OR parameterId IN ('M_G_P_020_001_001', 'HMGULA_OWT_023_001');

# Images
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Images')
WHERE group_name <> 'Weight'
  AND (
        LOWER(parameter_id) LIKE '%_xry%' OR
        LOWER(parameter_id) LIKE '%_dxa%' OR
        LOWER(parameter_id) LIKE '%_csd%' OR
        LOWER(parameter_id) LIKE '%_ecg%' OR
        LOWER(parameter_name) LIKE '%shape%' OR
        LOWER(parameter_name) LIKE '%size%' OR
        LOWER(parameter_name) LIKE '%tail%' OR
        LOWER(parameter_id) LIKE '%eslim_006_001_035%'
      );

# Brain
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Brain')
WHERE group_name NOT IN ('Weight', 'Images')
  AND (
        LOWER(parameter_id) LIKE '%_acs%' OR
        LOWER(parameter_id) LIKE '%_fea%' OR
        LOWER(procedure_name) LIKE '%brain%' OR
        LOWER(parameter_name) LIKE '%startle%' OR
        LOWER(parameter_name) LIKE '%inhibition%'
      );

# Eye Morphology
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Eye')
WHERE LOWER(parameter_id) LIKE '%_eye%';

# Hematology
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Hematology')
WHERE
    LOWER(parameter_id) LIKE '%_hem%' OR
    LOWER(parameter_name) LIKE '%hemoglobin%' OR
    LOWER(parameter_name) LIKE '%platelet%' OR
    LOWER(parameter_name) LIKE '%volume%';

# CBC Chemistry
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'CBC Chemistry')
WHERE
    LOWER(parameter_id) LIKE '%_cbc%' OR
    LOWER(parameter_name) LIKE '%ide%' OR
    (LOWER(parameter_name) LIKE '%ase%' AND LOWER(parameter_name) NOT LIKE '%baseline%') OR
    LOWER(parameter_name) LIKE '%glucose%' OR
    LOWER(parameter_name) LIKE '%cholesterol%' OR
    LOWER(parameter_name) LIKE '%creatinine%' OR
    LOWER(parameter_name) LIKE '%calcium%' OR
    LOWER(parameter_name) LIKE '%urea%';

# Morphology/Development
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Morphology/Development')
WHERE group_name <> 'Images'
  AND (
        LOWER(parameter_id) LIKE '%_gel%' OR
        LOWER(parameter_id) LIKE '%_gep%'
      );

# Activity/Movement
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Activity/Movement')
WHERE group_name NOT IN ('Images', 'Brain')
  AND (
       LOWER(parameter_id) LIKE '%_grs%' OR
       LOWER(parameter_id) LIKE '%_ofd%' OR
       LOWER(parameter_name) LIKE '%distance%' OR
       LOWER(parameter_name) LIKE '%movement%' OR
       LOWER(parameter_name) LIKE '%time%' OR
       LOWER(parameter_name) LIKE '%speed%'
      );

# Immunology
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Immunology')
WHERE group_name <> 'Images'
  AND (
       LOWER(parameter_name) LIKE '%t cell%' OR
       LOWER(parameter_name) LIKE '%treg%'
      );

# Echocardiography
UPDATE PARAMETER_DESCRIPTION
SET GROUP_ID = (SELECT GROUP_ID FROM PARAMETER_GROUPINGS WHERE GROUP_NAME = 'Echocardiography')
WHERE LOWER(procedure_name) LIKE '%echo%';




# CHECK PATHS WORK 

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
