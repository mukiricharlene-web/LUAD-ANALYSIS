WITH expression_category AS (
SELECT
    DISTINCT survival.patient_id,
    survival.survival_time,
    survival.survival_status,
    MAX(CASE 
        WHEN gene_map.gene_name = 'CD8A' THEN gene_expression.expression 
    END) AS cd8a_expression,
    MAX(CASE 
        WHEN gene_map.gene_name = 'IFNG' THEN gene_expression.expression 
    END) AS ifng_expression
FROM
    survival
JOIN 
    gene_expression ON gene_expression.patient_id = survival.patient_id
JOIN 
    gene_map ON gene_expression.gene = gene_map.gene_id
WHERE 
    gene_map.gene_name IN ('CD8A', 'IFNG')
GROUP BY 
    survival.survival_time,
    survival.survival_status,
    survival.patient_id
)
SELECT *,
     CASE 
        WHEN NTILE(3) OVER (ORDER BY cd8a_expression) = 1 THEN 'low'
        WHEN NTILE(3) OVER (ORDER BY cd8a_expression) = 2 THEN 'mid'
        ELSE 'high'
    END AS cd8a_group,
     CASE 
        WHEN NTILE(3) OVER (ORDER BY ifng_expression) = 1 THEN 'low'
        WHEN NTILE(3) OVER (ORDER BY ifng_expression) = 2 THEN 'mid'
        ELSE 'high'
    END AS ifng_group
FROM
    expression_category
ORDER BY 
    survival_time DESC,
    survival_status DESC;