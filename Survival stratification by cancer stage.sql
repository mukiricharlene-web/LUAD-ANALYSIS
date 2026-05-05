 SELECT 
    CASE
        WHEN survival_time < 1825 THEN 'low_survival'
        WHEN survival_time  BETWEEN 1825 AND 3650 THEN 'mid_survival'
        ELSE 'great_survival'
        END AS stratified_survival,
    CASE 
        WHEN cancer_stage IN ('Stage IA', 'Stage IB', 'Stage I') THEN 'Stage I'
        WHEN cancer_stage IN ('Stage IIA', 'Stage IIB', 'Stage II') THEN 'Stage II'
        WHEN cancer_stage IN ('Stage IIIA', 'Stage IIIB') THEN 'Stage III'
        ELSE cancer_stage 
    END AS simplified_stage,
    COUNT(phenotype.patient_id) AS patient_count
FROM
    phenotype
JOIN
    survival ON survival.patient_id = phenotype.patient_id
WHERE
    cancer_stage IS NOT NULL AND cancer_stage <>''
GROUP BY
    simplified_stage,
    stratified_survival
ORDER BY
    stratified_survival ASC;  
  