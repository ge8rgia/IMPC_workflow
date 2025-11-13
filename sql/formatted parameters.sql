#I did this bit manually but wrote a code to do this: 
#SELECT parameter_id, parameter_name FROM cleaned_merged_output
#WHERE parameter_name in (
#'Platelet count', 'Platelets-count', 
#'Mean cell haemoglobin concentration', 'Mean cell hemoglobin concentration', 
#'Mean cell volume', 'Mean-cell-volume', 
#'Mean corpuscular haemoglobin', 'Mean corpuscular hemoglobin', 'Mean-corpuscular-haemoglobin');

UPDATE cleaned_merged_output
SET parameter_name = 'Platelet count', parameter_id = 'IMPC_HEM_008_001' 
WHERE parameter_id = 'M_G_P_016_001_008';

UPDATE cleaned_merged_output
SET parameter_name = 'Mean cell haemoglobin concentration', parameter_id = 'IMPC_HEM_007_001' 
WHERE parameter_id IN ('IMPC_HEM_007_001', 'ESLIM_016_001_007');

UPDATE cleaned_merged_output
SET parameter_name = 'Mean cell volume', parameter_id = 'IMPC_HEM_005_001' 
WHERE parameter_id = 'M_G_P_016_001_005';

UPDATE cleaned_merged_output
SET parameter_name = 'Mean corpuscular haemoglobin', parameter_id = 'IMPC_HEM_006_001' 
WHERE parameter_id IN ('IMPC_HEM_006_001', 'M_G_P_016_001_006', 'ESLIM_016_001_006');
