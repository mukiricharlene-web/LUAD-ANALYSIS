WITH immune_prescence AS (
SELECT
    DISTINCT survival.patient_id,
    MAX(CASE 
        WHEN gene_map.gene_name = 'CD8A' THEN gene_expression.expression 
    END) AS cd8a_expression,
    MAX(CASE 
        WHEN gene_map.gene_name = 'IFNG' THEN gene_expression.expression 
    END) AS ifng_expression,
      CASE 
        WHEN cancer_stage IN ('Stage IA', 'Stage IB', 'Stage I') THEN 'Stage I'
        WHEN cancer_stage IN ('Stage IIA', 'Stage IIB', 'Stage II') THEN 'Stage II'
        WHEN cancer_stage IN ('Stage IIIA', 'Stage IIIB') THEN 'Stage III'
        ELSE cancer_stage 
    END AS simplified_stage
FROM
    survival
JOIN 
    gene_expression ON gene_expression.patient_id = survival.patient_id
JOIN 
    gene_map ON gene_expression.gene = gene_map.gene_id
JOIN
    phenotype ON gene_expression.patient_id = phenotype.patient_id
WHERE 
    gene_map.gene_name IN ('CD8A', 'IFNG') AND cancer_stage IS NOT NULL AND cancer_stage <>''
GROUP BY 
    simplified_stage,
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
    immune_prescence
ORDER BY 
   cd8a_expression DESC,
   ifng_expression DESC;