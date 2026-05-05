SELECT
    gene_map.gene_name,
    gene_expression.expression,
    CASE
        WHEN phenotype.cancer_stage IN ('Stage IA', 'Stage IB', 'Stage I') THEN 'Stage I'
        WHEN phenotype.cancer_stage IN ('Stage IIA', 'Stage IIB', 'Stage II') THEN 'Stage II'
        WHEN phenotype.cancer_stage IN ('Stage IIIA', 'Stage IIIB') THEN 'Stage III'
        WHEN phenotype.cancer_stage = 'Stage IV' THEN 'Stage IV'
        ELSE 'Unknown'
    END AS stage_group,
    COUNT(DISTINCT gene_expression.patient_id) AS patient_count
FROM
    gene_expression
JOIN
    gene_map ON gene_expression.gene = gene_map.gene_id
JOIN
    phenotype ON gene_expression.patient_id = phenotype.patient_id
WHERE
    gene_map.gene_name = 'CD8A' AND cancer_stage IS NOT NULL AND cancer_stage <>''
GROUP BY
    gene_map.gene_name,
    stage_group,
    gene_expression.expression

ORDER BY
    patient_count DESC;