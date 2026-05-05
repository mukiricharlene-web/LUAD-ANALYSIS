
WITH stratified_cancer AS
    (SELECT
    CASE 
        WHEN cancer_stage IN ('Stage IA', 'Stage IB', 'Stage I') THEN 'Stage I'
        WHEN cancer_stage IN ('Stage IIA', 'Stage IIB', 'Stage II') THEN 'Stage II'
        WHEN cancer_stage IN ('Stage IIIA', 'Stage IIIB') THEN 'Stage III'
        ELSE cancer_stage 
    END AS simplified_stage,
    ROUND(AVG(survival_time)::numeric, 2) AS avg_survival_days, 
    COUNT(*) AS patient_count
FROM phenotype
JOIN survival ON phenotype.patient_id = survival.patient_id
WHERE cancer_stage IS NOT NULL 
  AND cancer_stage <> '' 
GROUP BY simplified_stage
ORDER BY avg_survival_days DESC)

SELECT
    simplified_stage,
    DISTINCT patient_count,
    avg_survival_days
FROM   
    stratified_cancer
WHERE
    simplified_stage IS NOT NULL
ORDER BY
    patient_count DESC;