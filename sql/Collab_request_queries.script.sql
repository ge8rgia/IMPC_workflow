
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


#Query for All information regarding their genotype of interest
SELECT DISTINCT
    g.Gene_symbol,
    pad.parameter_name,
    pg.Group_name AS Parameter_Group,
    pad.pvalue,
    pr.procedure_name,
    d.DO_Disease_name AS Disease_Association
FROM Genes g
JOIN Phenotype_analysis_data pad 
    ON g.Gene_Accession_id = pad.gene_accession_id
LEFT JOIN Parameters p 
    ON pad.parameter_id = p.parameter_id
LEFT JOIN Parameter_groups pg 
    ON p.Group_id = pg.Group_id
LEFT JOIN Parameter_OrigID po 
    ON pad.parameter_id = po.parameter_id
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl 
    ON po.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN Procedure_information pr 
    ON ppl.procedure_name = pr.procedure_name
LEFT JOIN MOUSE_GENE_DISEASE_LINK mgdl 
    ON g.Gene_Accession_id = mgdl.Gene_Accession_id
LEFT JOIN Disease_information d 
    ON mgdl.DO_Disease_id = d.DO_Disease_id
WHERE g.Gene_symbol IN ('Ido1', 'Atrip', 'Kif9', 'Tbc1d22a')
ORDER BY pad.pvalue ASC;



#Query for significant Hits within Database (15 results)
SELECT DISTINCT
    g.Gene_symbol,
    pad.parameter_name,
    pg.Group_name AS Parameter_Group,
    pad.pvalue,
    pr.procedure_name,
    d.DO_Disease_name AS Disease_Association
FROM Genes g
JOIN Phenotype_analysis_data pad 
    ON g.Gene_Accession_id = pad.gene_accession_id
LEFT JOIN Parameters p 
    ON pad.parameter_id = p.parameter_id
LEFT JOIN Parameter_groups pg 
    ON p.Group_id = pg.Group_id
LEFT JOIN Parameter_OrigID po 
    ON pad.parameter_id = po.parameter_id
LEFT JOIN PROCEDURE_PARAMETER_LINK ppl 
    ON po.impcParameterOrigID = ppl.impcParameterOrigID
LEFT JOIN Procedure_information pr 
    ON ppl.procedure_name = pr.procedure_name
LEFT JOIN MOUSE_GENE_DISEASE_LINK mgdl 
    ON g.Gene_Accession_id = mgdl.Gene_Accession_id
LEFT JOIN Disease_information d 
    ON mgdl.DO_Disease_id = d.DO_Disease_id
WHERE g.Gene_symbol IN ('Ido1', 'Atrip', 'Kif9', 'Tbc1d22a')
  AND pad.pvalue < 0.05 # significant results
ORDER BY pad.pvalue ASC;