# IMPC_SQL_Workflow FINAL SCRIPT

DROP DATABASE IF EXISTS IMPC_Database_FINAL;
CREATE DATABASE IMPC_Database_FINAL;
USE IMPC_Database_FINAL;
SET SQL_SAFE_UPDATES = 0;
SET GLOBAL local_infile=true;

# SECTION 1 - CREATING LINKED GENES TO OMIM DISEASE TABLES

# Create Genes table
CREATE TABLE Genes (
    Gene_Accession_id varchar(50) NOT NULL,
    Gene_symbol varchar(50),
    CONSTRAINT Genes_pk PRIMARY KEY (Gene_Accession_id)
);
# Insert unique gene data into Genes
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/clean_merged_data.csv'
IGNORE INTO TABLE Genes
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, Gene_Accession_ID, Gene_symbol, @skip, @skip, @skip, @skip, @skip);

# Create Disease_information table
CREATE TABLE Disease_information (
    DO_Disease_id varchar(50) NOT NULL, 
    DO_Disease_name varchar(255),
    CONSTRAINT PK_Disease PRIMARY KEY (DO_Disease_id)
);
# Insert unique disease_id data into Disease_information 
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/disease_information_clean.csv'
IGNORE INTO TABLE Disease_information
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, DO_Disease_Name, @skip, @skip);

# Link Gene and Disease_information with a new table
CREATE TABLE MOUSE_GENE_DISEASE_LINK (
    id INT AUTO_INCREMENT NOT NULL,
    DO_Disease_id varchar(50),
    Gene_Accession_id varchar(50) NOT NULL,
    CONSTRAINT mouse_gene_disease_link PRIMARY KEY (id),
    CONSTRAINT FK_MGI FOREIGN KEY (DO_Disease_id) REFERENCES Disease_information(DO_Disease_id),
    CONSTRAINT fk_link_to_gene FOREIGN KEY (Gene_Accession_id) REFERENCES Genes(Gene_Accession_id),
    CONSTRAINT unique_mgi UNIQUE (DO_Disease_id, Gene_Accession_id)  # what does this do?
); 
# Load data onto MOUSE_GENE_DISEASE_LINK
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/disease_information_clean.csv'
IGNORE INTO TABLE MOUSE_GENE_DISEASE_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, @skip, @skip, Gene_Accession_id);

# Create OMIM_Disease_id table - which links to Disease_information
CREATE TABLE OMIM_Disease_id (
    id INT AUTO_INCREMENT NOT NULL,
    DO_Disease_id varchar(50),
    OMIM_id varchar(50) NOT NULL,
    CONSTRAINT OMIM_Disease_link PRIMARY KEY (id),
    CONSTRAINT Fk_omim FOREIGN KEY (DO_Disease_id) REFERENCES Disease_information(DO_Disease_id),
    CONSTRAINT unique_omim UNIQUE (DO_Disease_id, OMIM_id)
);
# Load data into OMIM_Disease_id
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/disease_information_clean.csv'
IGNORE INTO TABLE OMIM_Disease_id
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DO_Disease_id, @skip, OMIM_id, @skip);

# SECTION 2 - CREATING LINKED GENES TO PARAMETER AND PROCEDURE INFORMATION

CREATE TABLE Phenotype_analysis_data (
    analysis_id varchar(15) NOT NULL,
    gene_accession_id varchar(11),
    mouse_life_stage varchar(17),
    mouse_strain varchar(5),
    parameter_id varchar(20),
    parameter_name varchar(74),
    pvalue FLOAT NULL,
    CONSTRAINT Phenotype_analysis_data PRIMARY KEY (analysis_id),
    CONSTRAINT Fk_Analysis_to_gene FOREIGN KEY (gene_accession_id) REFERENCES Genes(Gene_Accession_id)
);
# Load data into Phenotype_analysis_data
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/clean_merged_data.csv'
IGNORE INTO TABLE Phenotype_analysis_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(analysis_id, gene_accession_id, @skip, mouse_life_stage, mouse_strain, parameter_id, parameter_name, @listpvalue)
SET pvalue = NULLIF(@listpvalue, 'NA'
);

# Create Parameters table 
# Start with a tmp file
CREATE TABLE Parameters (
	parameter_id varchar(20) NOT NULL,
	CONSTRAINT parameters_pk PRIMARY KEY (parameter_id),
	CONSTRAINT unique_parameter_id UNIQUE (parameter_id)
);
# Load data into Parameters table
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/clean_merged_data.csv'
IGNORE INTO TABLE Parameters
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, @skip, @skip, @skip, @skip, parameter_id, @skip, @skip);


# Link Parameters to Phenotype_analysis_data
ALTER TABLE Phenotype_analysis_data
ADD FOREIGN KEY (parameter_id)
    REFERENCES Parameters(parameter_id);

# Create Parameter_information table
CREATE TABLE Parameter_information (
	parameter_id varchar(20) NOT NULL,
	parameter_name varchar(74),
	parameter_description TEXT,
	parameter_information_id_fk varchar(20) NULL,
	CONSTRAINT parameter_id_key_pk PRIMARY KEY (parameter_id),
	CONSTRAINT unique_parameter_info_id UNIQUE (parameter_id)
);
# Load data onto Parameter_information
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/IMPC_parameter_clean.csv'
IGNORE INTO TABLE Parameter_information
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@skip, parameter_name, parameter_description, parameter_id
);
## Fill in fk only where an IMPC ID exists in Phenotype_analysis_data
UPDATE Parameter_information pi
JOIN Parameters p
    ON pi.parameter_id = p.parameter_id
SET pi.parameter_information_id_fk = p.parameter_id;
## Join the Parameters and Parameter_information tables
ALTER TABLE Parameter_information
ADD FOREIGN KEY (parameter_information_id_fk)
    REFERENCES Parameters(parameter_id);

# Create Parameter_OrigID table
CREATE TABLE Parameter_OrigID (
    impcParameterOrigID INT NOT NULL,
    parameter_id varchar(20),
    parameter_information_id_fk varchar(20) NULL,
    CONSTRAINT parameter_OrigID_pk PRIMARY KEY (impcParameterOrigID)
);
# Load data into Parameter_OrigID
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/IMPC_parameter_clean.csv'
IGNORE INTO TABLE Parameter_OrigID
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(impcParameterOrigID, @skip, @skip, parameter_id);

# Link Parameter_OrigID to Parameters
## Fill in fk only where an IMPC ID exists in Phenotype_analysis_data
UPDATE Parameter_OrigID pi
JOIN Parameters p
    ON pi.parameter_id = p.parameter_id
SET pi.parameter_information_id_fk = p.parameter_id;
## Join the Parameters and Parameter_information tables
ALTER TABLE Parameter_OrigID
ADD FOREIGN KEY (parameter_information_id_fk)
    REFERENCES Parameters(parameter_id);


# Create Procedure_information table
CREATE TABLE Procedure_information (
    procedure_name varchar(255) NOT NULL,
    procedure_description TEXT, 
    isMandatory BOOLEAN,
    CONSTRAINT IMPC_procedure_pk PRIMARY KEY (procedure_name)
);
# Load data into Procedure_information
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/IMPC_procedure_clean.csv'
IGNORE INTO TABLE Procedure_information
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(procedure_name, procedure_description, @listisMandatory, @skip)
SET isMandatory = (CASE
                      WHEN UPPER(@listisMandatory) = 'TRUE' THEN TRUE
                      ELSE FALSE
                   END
);

# Link Parameter_OrigID and Procedure_information with a new table
CREATE TABLE PROCEDURE_PARAMETER_LINK (
    id INT AUTO_INCREMENT,
    procedure_name varchar(255) NOT NULL,
    impcParameterOrigID INT,
    CONSTRAINT procedure_to_parameter_link_pk PRIMARY KEY (id),
    CONSTRAINT fk_link_to_procedure FOREIGN KEY (procedure_name) REFERENCES Procedure_information(procedure_name),
    CONSTRAINT fk_link_to_parameter FOREIGN KEY (impcParameterOrigID) REFERENCES Parameter_OrigID(impcParameterOrigID)
);
# Load data into linking table
LOAD DATA LOCAL INFILE '/Users/georgiagoddard/Desktop/DCDM_CW/final_data/IMPC_procedure_clean.csv'
IGNORE INTO TABLE PROCEDURE_PARAMETER_LINK
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(procedure_name, @skip, @skip, impcParameterOrigID);

# SECTION 3 - CREATING AND LINKING PARAMETER_GROUPS TO THE DATA

# Create Parameter_groups table
CREATE TABLE Parameter_groups (
    Group_id INT AUTO_INCREMENT,
    Group_name varchar(50) NOT NULL UNIQUE,
    CONSTRAINT Parameter_group_pk PRIMARY KEY (Group_id)
);
# Add pre-determined groups to table
INSERT INTO Parameter_groups (Group_name) VALUES
('Weight'), ('Images'), ('Brain'), ('Eye Morphology'), ('Hematology'), ('CBC Chemistry'), ('Morphology/Development'), ('Activity/Movement'), ('Immunology'), ('Echocardiography');

# Create a tmp table of parameter_ids in the study with their linked parameter_name and procedure_name 
# Needed to assign groups to parameter_ids
CREATE TABLE Group_information_tmp (
    parameter_id varchar(30) NOT NULL,
    parameter_name varchar(255),
    procedure_name varchar(255)
);
# Query so parameter_id is matched with the parameter_name and respective procedure_name.
INSERT INTO Group_information_tmp (parameter_id, parameter_name, procedure_name)
SELECT DISTINCT
    pad.parameter_id,
    pad.parameter_name,
    pr.procedure_name
FROM Phenotype_analysis_data pad
LEFT JOIN Parameter_OrigID po
    ON pad.parameter_id = po.parameter_id
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl
    ON po.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN Procedure_information pr
    ON ppl.procedure_name = pr.procedure_name;

# Create group names in new column:

ALTER TABLE Group_information_tmp
ADD COLUMN Group_id varchar(2) DEFAULT '';

# Weight
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Weight')
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
    OR parameter_id IN ('M_G_P_020_001_001', 'HMGULA_OWT_023_001'
	);

# Images
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Images')
WHERE group_id <> '1' # 1 = Weight
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
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Brain')
WHERE Group_id NOT IN ('1', '2')  # 1 = Weight, 2 = Images
  AND (
        LOWER(parameter_id) LIKE '%_acs%' OR
        LOWER(parameter_id) LIKE '%_fea%' OR
        LOWER(procedure_name) LIKE '%brain%' OR
        LOWER(parameter_name) LIKE '%startle%' OR
        LOWER(parameter_name) LIKE '%inhibition%'
      );

# Eye Morphology
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Eye Morphology')
WHERE LOWER(parameter_id) LIKE '%_eye%';

# Hematology
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Hematology')
WHERE
    LOWER(parameter_id) LIKE '%_hem%' OR
    LOWER(parameter_name) LIKE '%hemoglobin%' OR
    LOWER(parameter_name) LIKE '%platelet%' OR
    LOWER(parameter_name) LIKE '%volume%';

# CBC Chemistry
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'CBC Chemistry')
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
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Morphology/Development')
WHERE group_id <> '2' # 2 = Images
  AND (
        LOWER(parameter_id) LIKE '%_gel%' OR
        LOWER(parameter_id) LIKE '%_gep%'
      );

# Activity/Movement
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Activity/Movement')
WHERE group_id NOT IN ('2', '3') # 2 = Images, 3 = Brain
  AND (
       LOWER(parameter_id) LIKE '%_grs%' OR
       LOWER(parameter_id) LIKE '%_ofd%' OR
       LOWER(parameter_name) LIKE '%distance%' OR
       LOWER(parameter_name) LIKE '%movement%' OR
       LOWER(parameter_name) LIKE '%time%' OR
       LOWER(parameter_name) LIKE '%speed%'
      );

# Immunology
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Immunology')
WHERE group_id <> '2' # 2 = Images
  AND (
       LOWER(parameter_name) LIKE '%t cell%' OR
       LOWER(parameter_name) LIKE '%treg%'
      );

# Echocardiography
UPDATE Group_information_tmp
SET Group_id = (SELECT Group_id FROM Parameter_groups WHERE Group_name = 'Echocardiography')
WHERE LOWER(procedure_name) LIKE '%echo%';


# Add Group_id column to Parameters table
ALTER TABLE Parameters
ADD COLUMN Group_id INT NULL;
ALTER TABLE Parameters
ADD FOREIGN KEY (Group_id)
    REFERENCES Parameter_groups(Group_id);

# Add associated groups to the Parameters table
UPDATE Parameters p
JOIN Group_information_tmp g
     ON p.parameter_id = g.parameter_id
SET p.Group_id = g.Group_id;

DROP TABLE if EXISTS Group_information_tmp;

