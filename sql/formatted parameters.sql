UPDATE cleaned_merged_output
SET parameter_name = 'Platelet count'
WHERE pparameter_name = 'Platelets count';

UPDATE cleaned_merged_output
SET parameter_name = 'Mean cell haemoglobin concentration'
WHERE parameter_name = 'Mean cell hemoglobin concentration';

UPDATE cleaned_merged_output
SET parameter_name = 'Mean cell volume'
WHERE parameter_name = 'Mean-cell-volume';

UPDATE cleaned_merged_output
SET parameter_name = 'Mean corpuscular haemoglobin'
WHERE parameter_name IN ('Mean corpuscular hemoglobin', 'Mean-corpuscular-haemoglobin');
