WITH checkpoint_inhibitors AS (
    SELECT
    survival.patient_id,
    survival_time,
    survival_status,
    MAX(CASE 
        WHEN gene_map.gene_name = 'PDCD1' THEN gene_expression.expression 
    END) AS pdcd1_expression,
    MAX(CASE 
        WHEN gene_map.gene_name = 'CD274' THEN gene_expression.expression 
    END) AS cd274_expression,
    MAX(CASE 
        WHEN gene_map.gene_name = 'LAG3' THEN gene_expression.expression 
    END) AS lag3_expression,
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
    gene_map ON gene_map.gene_id = gene_expression.gene
WHERE
    gene_name IN ('PDCD1','CD274','LAG3','CD8A','IFNG') 
GROUP BY
    survival.patient_id,
    survival_status,
    survival_time
),
ranked AS (
    SELECT *,
        NTILE(3) OVER (ORDER BY pdcd1_expression) AS pdcd1_tile,
        NTILE(3) OVER (ORDER BY cd274_expression) AS cd274_tile,
        NTILE(3) OVER (ORDER BY lag3_expression) AS lag3_tile,
        NTILE(3) OVER (ORDER BY cd8a_expression) AS cd8a_tile,
        NTILE(3) OVER (ORDER BY ifng_expression) AS ifng_tile
    FROM 
        checkpoint_inhibitors
    WHERE 
        pdcd1_expression IS NOT NULL
        AND cd274_expression IS NOT NULL
        AND lag3_expression IS NOT NULL
        AND cd8a_expression IS NOT NULL
        AND ifng_expression IS NOT NULL
)
SELECT 
    patient_id,
    survival_time,
    survival_status,
    CASE pdcd1_tile 
        WHEN 1 THEN 'low'
        WHEN 2 THEN 'mid'
        ELSE 'high'
    END AS pdcd1_group,
    CASE cd274_tile 
        WHEN 1 THEN 'low'
        WHEN 2 THEN 'mid'
        ELSE 'high'
    END AS cd274_group,
    CASE lag3_tile 
        WHEN 1 THEN 'low'
        WHEN 2 THEN 'mid'
        ELSE 'high'
    END AS lag3_group,
    CASE
        WHEN cd8a_tile = 3 AND ifng_tile = 3 THEN 'functional_immunity'
        WHEN cd8a_tile = 3 AND ifng_tile = 1 THEN 'inactive_immunity'
        ELSE 'heterogeneous'
    END AS immune_prescence,
    CASE 
        WHEN pdcd1_tile = 3 AND lag3_tile = 3 THEN 'co-exhausted_high'
        WHEN pdcd1_tile = 1 AND lag3_tile = 1 THEN 'immune_cold'
        ELSE 'intermediate'
    END AS immune_phenotype
FROM 
    ranked
ORDER BY 
    survival_time DESC, 
    survival_status DESC;
        

