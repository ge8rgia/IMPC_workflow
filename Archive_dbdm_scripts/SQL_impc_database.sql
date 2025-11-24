
DROP DATABASE IF EXISTS IMPC_Workflow_v2;
CREATE DATABASE IMPC_Workflow_v2;
USE IMPC_Workflow_v2;

# IMPC_Workflow_v2
# Attempt n2 at joining tables

# SECTION 1 - JOINING MERGED_DATA WITH PROCEDURE METADATA

# Generate Initial Merged Data Table 
CREATE TABLE IMPC_Workflow_v2.merged_data (
    analysis_id varchar(15) NOT NULL,
    gene_accession_id varchar(11),
    gene_symbol varchar(13),
    mouse_life_stage varchar(17),
    mouse_strain varchar(5),
    parameter_id varchar(20),
    parameter_name varchar(74),
    pvalue FLOAT NULL,
    CONSTRAINT merged_data_pk PRIMARY KEY (analysis_id),
    CONSTRAINT analysis_id_length CHECK (LENGTH(analysis_id) = 15),
    CONSTRAINT gene_accession_id_length CHECK (LENGTH(gene_accession_id) between 9 and 11),
    CONSTRAINT gene_symbol_id_length CHECK (LENGTH(gene_symbol) between 1 and 13),
    CONSTRAINT mouse_life_stage_length CHECK (LENGTH(mouse_life_stage) between 4 and 17 OR mouse_life_stage = 'NA'),
    CONSTRAINT mouse_strain_length CHECK (LENGTH(mouse_strain) between 3 and 5),
    CONSTRAINT parameter_id_length CHECK (LENGTH(parameter_id) between 15 and 20),
    CONSTRAINT parameter_name_length CHECK (LENGTH(parameter_name) between 2 and 74),
    CONSTRAINT pvalue_range CHECK (pvalue between 0 and 1)
);
# Insert data using merged_data -> Import Data -> From csv -> cleaned_merged_output_v2.csv

# Generate IMPC_Parameter_Description Table 
CREATE TABLE IMPC_Workflow_v2.IMPC_parameter_description (
	impcParameterOrigId varchar(5) NOT NULL,
	name TEXT,
	description TEXT,
	parameter_id varchar(20),
	CONSTRAINT IMPC_parameter_description_pk PRIMARY KEY (impcParameterOrigId),
	CONSTRAINT parameter_id_length2 CHECK (LENGTH(parameter_id) between 15 and 20)
);
# Insert data using merged_data -> Import Data -> From csv -> cleaned_parameters.csv

# Generate Parameter_information Table
CREATE TABLE IMPC_Workflow_v2.Parameter_information (
	parameter_id_key INT AUTO_INCREMENT,
	parameter_id varchar(20) NOT NULL,
	parameter_name varchar(74),
	source varchar(6),
	CONSTRAINT parameter_id_key_pk PRIMARY KEY (parameter_id_key)
);
# Insert data using merged_data -> Import Data -> From csv -> Parameters.csv

# Create Parameter Table 
CREATE TABLE IMPC_Workflow_v2.Parameters (
    parameter_id varchar(20) PRIMARY KEY,
    source varchar(6),
    parameter_information_id INT NULL
);
# Add foreign key to this table
ALTER TABLE IMPC_Workflow_v2.Parameters
ADD FOREIGN KEY (parameter_information_id)
    REFERENCES IMPC_Workflow_v2.Parameter_information(parameter_id_key);
# Add data into table
INSERT INTO IMPC_Workflow_v2.Parameters (parameter_id, source)
SELECT parameter_id, source
FROM IMPC_Workflow_v2.Parameter_information;
# Join IMPC Parameters with values as the foreign key
UPDATE IMPC_Workflow_v2.Parameters param
JOIN IMPC_Workflow_v2.Parameter_information info
    ON param.parameter_id = info.parameter_id
SET param.parameter_information_id = 
    CASE 
        WHEN info.source = 'IMPC' THEN info.parameter_id_key
        ELSE NULL
    END;
# No more need for source column in Parameters
ALTER TABLE IMPC_Workflow_v2.Parameters
DROP COLUMN source;

# Link Parameters to merged_data table
ALTER TABLE IMPC_Workflow_v2.merged_data
ADD FOREIGN KEY (parameter_id)
    REFERENCES IMPC_Workflow_v2.Parameters(parameter_id);

# Now link Parameters to IMPC_Parameter_Description
## Add nullable fk to IMPC_Parameter_Description
ALTER TABLE IMPC_Workflow_v2.IMPC_parameter_description
ADD COLUMN parameter_fk varchar(20) NULL;
## Fill in fk only where an IMPC ID exists in merged_data
UPDATE IMPC_Workflow_v2.IMPC_parameter_description a
JOIN IMPC_Workflow_v2.Parameters b
    ON a.parameter_id = b.parameter_id
SET a.parameter_fk = b.parameter_id;
## Join the Parameters and IMPC_Parameter_Description tables
ALTER TABLE IMPC_Workflow_v2.IMPC_parameter_description
ADD FOREIGN KEY (parameter_fk)
    REFERENCES IMPC_Workflow_v2.Parameters(parameter_id);


# Check to see if matching works (spoiler it does! yay!)
SELECT DISTINCT
    d.impcParameterOrigId,
    m.parameter_id,
    m.parameter_name
FROM IMPC_Workflow_v2.merged_data m
LEFT JOIN IMPC_Workflow_v2.Parameters p
    ON m.parameter_id = p.parameter_id
LEFT JOIN IMPC_Workflow_v2.IMPC_parameter_description d
    ON d.parameter_fk = p.parameter_id
WHERE m.parameter_id = 'IMPC_GEP_004_002';


# Generate an IMPC_procedure_id table
CREATE TABLE IMPC_Workflow_v2.IMPC_procedure_id (
	impcParameterOrigId varchar(5) NOT NULL,
	procedure_name varchar(255) NOT NULL,
	CONSTRAINT IMPC_procedure_id_pk PRIMARY KEY (impcParameterOrigId)
);
# Import data 
# Add procedure_name as a new column in the IMPC_parameter_description table
ALTER TABLE IMPC_Workflow_v2.IMPC_parameter_description
ADD COLUMN procedure_name varchar(255);
UPDATE IMPC_Workflow_v2.IMPC_parameter_description a
JOIN IMPC_Workflow_v2.IMPC_procedure_id b
    ON a.impcParameterOrigId = b.impcParameterOrigId
SET a.procedure_name = b.procedure_name;

# IMPC_procedure_id table can be deleted now
# Delete table
DROP TABLE IMPC_Workflow_v2.IMPC_procedure_id;

# Generate the IMPC_procedure table
CREATE TABLE IMPC_Workflow_v2.IMPC_procedure (
    id INT AUTO_INCREMENT NOT NULL,
	procedure_name varchar(255) NOT NULL,
    description TEXT,
    isMandatory varchar(5),
    CONSTRAINT IMPC_procedure_pk PRIMARY KEY (id),
    CONSTRAINT isMandatory CHECK (LENGTH(isMandatory) between 4 and 5)
);
# Data from procedure file has duplicates, so delete duplicate data
DELETE p1
FROM IMPC_Workflow_v2.IMPC_procedure p1
JOIN IMPC_Workflow_v2.IMPC_procedure p2
    ON p1.procedure_name = p2.procedure_name
   AND p1.id > p2.id;
# Make procedure_name the primary key now
ALTER TABLE IMPC_Workflow_v2.IMPC_procedure
MODIFY id INT;
ALTER TABLE IMPC_Workflow_v2.IMPC_procedure
DROP PRIMARY KEY;
ALTER TABLE IMPC_Workflow_v2.IMPC_procedure
DROP COLUMN id;
ALTER TABLE IMPC_Workflow_v2.IMPC_procedure
ADD PRIMARY KEY (procedure_name);

# Create link between IMPC_parameter_description and IMPC_procedure
ALTER TABLE IMPC_Workflow_v2.IMPC_parameter_description
ADD FOREIGN KEY (procedure_name)
    REFERENCES IMPC_Workflow_v2.IMPC_procedure(procedure_name);

# YEAAAAAA LINKED!!!!

# Check to see it works right through
SELECT 
    d.impcParameterOrigId,
    d.parameter_id,
    d.procedure_name,
    p.description AS procedure_description,
    p.isMandatory
FROM IMPC_Workflow_v2.IMPC_parameter_description d
LEFT JOIN IMPC_Workflow_v2.IMPC_procedure p
       ON d.procedure_name = p.procedure_name
WHERE d.parameter_id = 'IMPC_GEP_004_002';
# IT WORKS YAAAAAA

# Check what happens on a NON-IMPC name
SELECT 
    d.impcParameterOrigId,
    d.parameter_id,
    d.procedure_name,
    p.description AS procedure_description,
    p.isMandatory
FROM IMPC_Workflow_v2.IMPC_parameter_description d
LEFT JOIN IMPC_Workflow_v2.IMPC_procedure p
       ON d.procedure_name = p.procedure_name
WHERE d.parameter_id = 'HMGULA_OFD_010_001';
# Brings up nothing -> no link

# SECTION 2 - JOINING MERGED_DATA WITH OMIM DISEASE LINK

# Generate Gene Table 
CREATE TABLE IMPC_Workflow_v2.Gene (
    gene_accession_id varchar(11) NOT NULL,
    gene_symbol varchar(13),
    CONSTRAINT gene_pk PRIMARY KEY (gene_accession_id),
    CONSTRAINT gene_accession_id_length2 CHECK (LENGTH(gene_accession_id) between 9 and 11),
    CONSTRAINT gene_symbol__id_length2 CHECK (LENGTH(gene_symbol) between 1 and 13)
);
# Insert unique data from merged_data original table
INSERT INTO IMPC_Workflow_v2.Gene (gene_accession_id, gene_symbol)
SELECT DISTINCT gene_accession_id, gene_symbol
FROM IMPC_Workflow_v2.merged_data
WHERE gene_accession_id IS NOT NULL
  AND gene_symbol IS NOT NULL;
# Remove gene_symbol data from merged_data (no need for duplicates)
ALTER TABLE IMPC_Workflow_v2.merged_data 
DROP COLUMN gene_symbol;
# Add link between merged_data and Gene
ALTER TABLE IMPC_Workflow_v2.merged_data
ADD FOREIGN KEY (gene_accession_id)
    REFERENCES IMPC_Workflow_v2.Gene(gene_accession_id);

# Load entire disease table onto SQL
CREATE TABLE IMPC_Workflow_v2.tmp_disease_info (
	id INT AUTO_INCREMENT NOT NULL,
	DO_disease_id varchar(12) NOT NULL,
	DO_disease_name TEXT,
	OMIM_id varchar(11),
	Mouse_MGI_id varchar(11) NOT NULL,
	CONSTRAINT tmp_disease_info_pk PRIMARY KEY (id),
    CONSTRAINT Mouse_MGI_id CHECK (LENGTH(Mouse_MGI_id) between 9 and 11)
);
# Import data

# Create unique disease information table
CREATE TABLE IMPC_Workflow_v2.Disease_information (
	DO_disease_id varchar(12) NOT NULL,
	DO_disease_name TEXT,
	CONSTRAINT disease_informatin_pk PRIMARY KEY (DO_disease_id)
);
# Add unique data from tmp_disease_info
INSERT INTO IMPC_Workflow_v2.Disease_information (DO_disease_id, DO_disease_name)
SELECT DISTINCT DO_disease_id, DO_disease_name
FROM IMPC_Workflow_v2.tmp_disease_info
WHERE DO_disease_id IS NOT NULL
  AND DO_disease_name IS NOT NULL;

# Create unique OMIM_id and DO_disease_id table
CREATE TABLE IMPC_Workflow_v2.OMIM_Disease_id (
	id INT AUTO_INCREMENT NOT NULL,
	DO_disease_id varchar(12) NOT NULL,
	OMIM_id varchar(11),
	CONSTRAINT OMIM_Disease_id_pk PRIMARY KEY (id)
);
# Add unique combination data from tmp_disease_info
INSERT INTO IMPC_Workflow_v2.OMIM_Disease_id (DO_disease_id, OMIM_id)
SELECT DISTINCT DO_disease_id, OMIM_id
FROM IMPC_Workflow_v2.tmp_disease_info
WHERE OMIM_id IS NOT NULL;

# Create unique Mouse_to_Human table 
CREATE TABLE IMPC_Workflow_v2.Mouse_to_Human (
	id INT AUTO_INCREMENT NOT NULL,
	DO_disease_id varchar(12) NOT NULL,
	Mouse_MGI_id varchar(11),
	CONSTRAINT Mouse_to_Human_pk PRIMARY KEY (id)
);
# Add unique combination data from tmp_disease_info
INSERT INTO IMPC_Workflow_v2.Mouse_to_Human (DO_disease_id, Mouse_MGI_id)
SELECT DISTINCT DO_disease_id, Mouse_MGI_id
FROM IMPC_Workflow_v2.tmp_disease_info
WHERE DO_disease_id IS NOT NULL;

# Delete tmp_disease_info table
DROP TABLE IMPC_Workflow_v2.tmp_disease_info;

# Add links between new tables
ALTER TABLE IMPC_Workflow_v2.Mouse_to_Human
ADD FOREIGN KEY (DO_disease_id)
    REFERENCES IMPC_Workflow_v2.Disease_information(DO_disease_id);

ALTER TABLE IMPC_Workflow_v2.OMIM_Disease_id
ADD FOREIGN KEY (DO_disease_id)
    REFERENCES IMPC_Workflow_v2.Disease_information(DO_disease_id);

# Link between Gene and Mouse_to_Human
# Needs a nullable foreign key like the parameters did above
ALTER TABLE IMPC_Workflow_v2.Mouse_to_Human
ADD COLUMN Mouse_MGI_id_fk varchar(11) NULL;
## Fill in fk only where a gene_accession_id exists in Gene
UPDATE IMPC_Workflow_v2.Mouse_to_Human a
JOIN IMPC_Workflow_v2.Gene b
    ON a.Mouse_MGI_id = b.gene_accession_id 
SET a.Mouse_MGI_id_fk = b.gene_accession_id;
## Join the Parameters and IMPC_parameter_description tables
ALTER TABLE IMPC_Workflow_v2.Mouse_to_Human
ADD FOREIGN KEY (Mouse_MGI_id_fk)
    REFERENCES IMPC_Workflow_v2.Gene(gene_accession_id);

# YAY OH EM GEE ITS DONE!!!!! YAAAAAA!!!! SUCCESS!!!

# Check it works
SELECT DISTINCT g.gene_symbol
FROM IMPC_Workflow_v2.merged_data m
JOIN IMPC_Workflow_v2.Gene g
    ON m.gene_accession_id = g.gene_accession_id
WHERE m.parameter_id = 'IMPC_GEP_004_002';
# YAY SUCCESS

# STAGE 3 - ASSIGN GROUPINGS FOR QUERYING

CREATE TABLE IMPC_Workflow_v2.Parameter_groups (
	Group_id INT AUTO_INCREMENT,
	Group_name varchar(50) NOT NULL UNIQUE,
	CONSTRAINT Parameter_group_pk PRIMARY KEY (Group_id)
);










	