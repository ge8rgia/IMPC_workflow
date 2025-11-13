UPDATE Analysis
SET parameter_name = 'Platelet count'
WHERE parameter_name = 'Platelets count';

UPDATE Analysis
SET parameter_name = 'Mean cell haemoglobin concentration'
WHERE parameter_name = 'Mean cell hemoglobin concentration';

UPDATE Analysis
SET parameter_name = 'Mean cell volume'
WHERE parameter_name = 'Mean-cell-volume';

UPDATE Analysis
SET parameter_name = 'Mean corpuscular haemoglobin'
WHERE parameter_name IN ('Mean corpuscular hemoglobin', 'Mean-corpuscular-haemoglobin');
