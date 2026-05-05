SELECT
    CASE
        WHEN survival_time < 1825 THEN 'low_survival'
        WHEN survival_time  BETWEEN 1825 AND 3650 THEN 'mid_survival'
        ELSE 'great_survival'
        END AS stratified_survival,
    survival_status,
    expression,
    COUNT(DISTINCT survival.patient_id) AS patient_count
FROM
    survival
JOIN
    gene_expression ON survival.patient_id = gene_expression.patient_id
JOIN
    gene_map ON gene_expression.gene = gene_map.gene_id
WHERE
    gene_name = 'CD8A'
GROUP BY
    survival_status,
    stratified_survival,
    expression
ORDER BY
    survival_status ASC;


