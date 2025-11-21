# IMPC_SQL_Workflow QUERIES
## For research purposes 

# Shortcut names used throughout this document for simplicity
## Phenotype_analysis_data = pad
## Genes = g
## Parameters = p
## Parameter_groups = pg
## Parameter_information = pi
## Parameter_OrigID = po
## PROCEDURE_PARAMETER_LINK = ppl
## Procedure_information = pr
## MOUSE_GENE_DISEASE_LINK = mgd
## Disease_information = di
## OMIM_Disease_id = od

USE IMPC_Database_FINAL;

# List unique variables used in the research
## Following tables store unique values - no repetition
SELECT Group_name from Parameter_groups;
SELECT Gene_symbol from Genes;
SELECT parameter_id from Parameters;


# Link the association of the mouse genes to human disease from the Disease Ontology 
## Takes unique Gene_Accession_id used in the research and provides association to DO_Disease_name
## Link = DO_Disease_id
SELECT g.Gene_symbol, di.DO_Disease_name FROM MOUSE_GENE_DISEASE_LINK mgd
JOIN Genes g ON mgd.Gene_Accession_id = g.Gene_Accession_id
JOIN Disease_information di ON mgd.DO_Disease_id = di.DO_Disease_id;

# How many total pvalues were actually significant in the dataset
## Count number of Phenotype_analysis_data pvalues when pvalue<0.05
## pvalue threshold can be changed
SELECT COUNT(*) AS significant_pvalues from Phenotype_analysis_data where pvalue < 0.05;
## Count total number of recorded pvalues in the research 
SELECT COUNT(*) AS total_pvalues from Phenotype_analysis_data where pvalue IS NOT NULL;
# 25,092 pvalues recorded -> only 259 significant pvalues (p<0.05)
# 25,092 pvalues recorded -> 1,569 significant pvalues when p<0.10

# Which genes are these significant pvalues linked to 
## Find Gene_symbol from pvalue threshold input
## Link = Gene_Accession_id
SELECT DISTINCT g.Gene_symbol FROM Phenotype_analysis_data pad
JOIN Genes g ON pad.gene_accession_id = g.Gene_Accession_id
	WHERE pad.pvalue < 0.05;
# 64 of the 100 genes tested in the research gave rise to significant pvalues

# Show side-by-side the gene associated with the significant pvalue (p<0,05)
SELECT g.Gene_symbol, pad.pvalue FROM Phenotype_analysis_data pad
JOIN Genes g ON pad.gene_accession_id = g.Gene_Accession_id
	WHERE pad.pvalue < 0.05
	ORDER BY Gene_symbol;

# Find the procedure used to test a select parameter in the research
## Procedure data was not provided for parameter_ids that were not named 'IMPC_*' 
## For this reason, the following adds a step to clarify this when querying
## Disadvantage of the following is that the parameter_id in question must be entered twice for command to function
## One parameter_id could be linked to multiple impcParameterOrigID, but these would link to the same procedure_name
## So we SELECT DISTINCT to not return multiple columns of the same procedure_name and procedure_description
( SELECT DISTINCT pr.procedure_name, pr.procedure_description FROM Parameter_OrigID po
  JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
  JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
    	WHERE po.parameter_id = 'IMPC_CSD_033_001'
)
UNION ALL
(
  SELECT
        'No procedure information provided for this parameter' AS procedure_name,
        'No description available' AS procedure_description
  WHERE NOT EXISTS (
   SELECT 1 FROM Parameter_OrigID po
   JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
   JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
         WHERE po.parameter_id = 'IMPC_CSD_033_001'
    )
);

# Select for all parameter_ids associated to one parameter Group_name
# Group_names = Weight, Images, Brain, Eye Morphology, Hematology, CBC Chemistry, Morphology/Development, Activity/Movement, Immunology, Echocardiography
SELECT p.parameter_id FROM Parameter_groups pg
JOIN Parameters p ON pg.Group_id = p.Group_id WHERE pg.Group_name = 'Activity/Movement';


# Find what procedures were used by one parameter group in the research
## Process:
## Find parameter_ids associated to one group through their Group_id
## Find the associated impcParameterOrigID associated with these parameter_ids
## LINK impcParameterOrigID to procedure_name to give procedure_description as well
## Final link from joining table to final values desired table using procedure_name as link 
SELECT DISTINCT pr.procedure_name, pr.procedure_description FROM Parameters p
JOIN Parameter_groups pg ON p.Group_id = pg.Group_id
JOIN Parameter_OrigID po ON p.parameter_id = po.parameter_id
JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name 
	WHERE pg.Group_name = 'Activity/Movement';


# Find which parameters were tested in one parameter group in the research
# More telling of the data than the above -> procedure_name does not specify which value was recorded
SELECT DISTINCT pi.parameter_name, pi.parameter_description FROM Parameters p
JOIN Parameter_groups pg ON p.Group_id = pg.Group_id
JOIN Parameter_information pi ON p.parameter_id = pi.parameter_information_id_fk
	WHERE pg.Group_name = 'Activity/Movement';


# Identify which of the metadata procedures were used to test a parameter
## Tables Parameters and Procedure_information need to be linked
## Link = impcParameterOrigID
SELECT DISTINCT pr.procedure_name, pr.procedure_description FROM Parameters p
JOIN Parameter_OrigID po ON p.parameter_id = po.parameter_id
JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
	ORDER BY pr.procedure_name;
## Only 19 of the 51 procedures were actually used in our research
## Note the limitation that is only telling of the 'IMPC_*' parameter_ids
## There is no procedure data on the rest

# Identify the parameter_id's in the research that are linked to a procedure identified above
## Plug in procedure_name from the above mentioned list
SELECT DISTINCT po.parameter_id FROM Procedure_information pr
JOIN PROCEDURE_PARAMETER_LINK ppl ON pr.procedure_name = ppl.procedure_name
JOIN Parameter_OrigID po ON ppl.impcParameterOrigID = po.impcParameterOrigID
JOIN Parameters p ON po.parameter_id = p.parameter_id
	WHERE pr.procedure_name = 'Clinical Chemistry';
## Note the limitation that this will only return 'IMPC_*' parameter_id's 


# Filter for the procedures present in the dataset that were mandatory for a standard IMPC research pipeline
## Tables must link between Parameters and Procedure_information
## Procedure is mandatory if isMandatory = TRUE = 1 (boolean)
## Procedure is not mandatory if isMandatory = TRUE = 1 (boolean)
## Link = impcParameterOrigID
### MANDATORY
SELECT DISTINCT pr.procedure_name, pr.procedure_description FROM Parameters p
JOIN Parameter_OrigID po ON p.parameter_id = po.parameter_id
JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
	WHERE pr.isMandatory = TRUE
	ORDER BY pr.procedure_name;
### NOT MANDATORY
SELECT DISTINCT pr.procedure_name, pr.procedure_description FROM Parameters p
JOIN Parameter_OrigID po ON p.parameter_id = po.parameter_id
JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
	WHERE pr.isMandatory = FALSE
	ORDER BY pr.procedure_name;
# 14 of the 19 procedures used in the research were mandatory
# The 5 procedures not mandatory for a standard IMPC research pipeline:
# Echo (functionality of the heart), Fear Conditioning (for learning and memory), Gross Morphology Embryo E18.5, Gross Morphology Embryo E9.5, Organ Weight


# Query a target value and return all information accessible by database

## Find all results on a select value
SELECT DISTINCT
    g.Gene_symbol,
    g.Gene_Accession_id,
    pi.parameter_id,
    pi.parameter_name,
    pi.parameter_description,
    pg.Group_name,
    pr.procedure_name,
    pr.procedure_description,
    pad.pvalue,
    (pad.pvalue < 0.05) AS significant_result,
    di.DO_Disease_name
FROM Genes g
LEFT JOIN Phenotype_analysis_data pad ON g.Gene_Accession_id = pad.gene_accession_id
LEFT JOIN Parameter_information pi ON pad.parameter_id = pi.parameter_id
LEFT JOIN Parameters p ON pad.parameter_id = p.parameter_id
LEFT JOIN Parameter_groups pg ON p.Group_id = pg.Group_id
LEFT JOIN Parameter_OrigID po ON pad.parameter_id = po.parameter_id
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
LEFT JOIN MOUSE_GENE_DISEASE_LINK mgd ON g.Gene_Accession_id = mgd.Gene_Accession_id
LEFT JOIN Disease_information di ON mgd.DO_Disease_id = di.DO_Disease_id
	# Query variable:
	WHERE pg.Group_name = 'Activity/Movement';

## Show only the significant results
SELECT DISTINCT
    g.Gene_symbol,
    g.Gene_Accession_id,
    pi.parameter_id,
    pi.parameter_name,
    pi.parameter_description,
    pg.Group_name,
    pr.procedure_name,
    pr.procedure_description,
    pad.pvalue,
    di.DO_Disease_name
FROM Genes g
LEFT JOIN Phenotype_analysis_data pad ON g.Gene_Accession_id = pad.gene_accession_id
LEFT JOIN Parameter_information pi ON pad.parameter_id = pi.parameter_id
LEFT JOIN Parameters p ON pad.parameter_id = p.parameter_id
LEFT JOIN Parameter_groups pg ON p.Group_id = pg.Group_id
LEFT JOIN Parameter_OrigID po ON pad.parameter_id = po.parameter_id
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl ON po.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN Procedure_information pr ON ppl.procedure_name = pr.procedure_name
LEFT JOIN MOUSE_GENE_DISEASE_LINK mgd ON g.Gene_Accession_id = mgd.Gene_Accession_id
LEFT JOIN Disease_information di ON mgd.DO_Disease_id = di.DO_Disease_id
	# Query variable:
	WHERE pg.Group_name = 'Activity/Movement'
  	AND pad.pvalue < 0.05;

# Querying for variables other than Gene_symbol
## Other variables can be substituted into the WHERE command 
## Limitation is that the researcher must be aware of the 'shortcut name' given to the table the variable of interest is accessed from
## e.g., pi = Parameter_information
## A list of table 'shortcut names' is provided at the start of this document
### e.g.,
### g.Gene_symbol = 'Ercc5'
### pi.parameter_id = 'IMPC_HWT_002_001'
### pi.parameter_name = 'Calcium'
### di.DO_Disease_name = 'Xeroderma pigmentosum group g'
### pr.procedure_name = 'Echo'
### pg.Group_name = 'Activity/Movement'