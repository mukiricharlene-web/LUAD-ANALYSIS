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
        





WITH immune_data AS (
    SELECT
        survival.patient_id,
        survival.survival_time,
        survival.survival_status,
        MAX(CASE
            WHEN gene_map.gene_name = 'CD8A'
            THEN gene_expression.expression
        END) AS cd8a_expression,
        MAX(CASE
            WHEN gene_map.gene_name = 'IFNG'
            THEN gene_expression.expression
        END) AS ifng_expression,
        MAX(CASE
            WHEN gene_map.gene_name = 'PDCD1'
            THEN gene_expression.expression
        END) AS pdcd1_expression,
        MAX(CASE
            WHEN gene_map.gene_name = 'LAG3'
            THEN gene_expression.expression
        END) AS lag3_expression,
        MAX(CASE
            WHEN gene_map.gene_name = 'CD274'
            THEN gene_expression.expression
        END) AS cd274_expression

FROM 
    survival
JOIN gene_expression ON gene_expression.patient_id = survival.patient_id
JOIN gene_map ON gene_map.gene_id = gene_expression.gene
WHERE 
    gene_map.gene_name IN ('CD8A','IFNG','PDCD1','LAG3','CD274')
GROUP BY
    survival.patient_id,
    survival.survival_time,
    survival.survival_status
),
stats AS (
    SELECT
        AVG(cd8a_expression) AS mean_cd8a,
        STDDEV(cd8a_expression) AS sd_cd8a,
        AVG(ifng_expression) AS mean_ifng,
        STDDEV(ifng_expression) AS sd_ifng,
        AVG(pdcd1_expression) AS mean_pdcd1,
        STDDEV(pdcd1_expression) AS sd_pdcd1,
        AVG(lag3_expression) AS mean_lag3,
        STDDEV(lag3_expression) AS sd_lag3,
        AVG(cd274_expression) AS mean_cd274,
        STDDEV(cd274_expression) AS sd_cd274
FROM 
    immune_data
),
normalized AS (
    SELECT
       immune_data.*,
        (cd8a_expression - mean_cd8a)
            / NULLIF(sd_cd8a, 0) AS cd8a_z,
        (ifng_expression - mean_ifng)
            / NULLIF(sd_ifng, 0) AS ifng_z,
        (pdcd1_expression - mean_pdcd1)
            / NULLIF(sd_pdcd1, 0) AS pdcd1_z,
        (lag3_expression - mean_lag3)
            / NULLIF(sd_lag3, 0) AS lag3_z,
        (cd274_expression - mean_cd274)
            / NULLIF(sd_cd274, 0) AS cd274_z
FROM 
    immune_data 
CROSS JOIN 
    stats
),
features AS (
    SELECT
        *,
        (cd8a_z + ifng_z)
            AS immune_activation_axis,
        (pdcd1_z + lag3_z + cd274_z)
            AS immune_suppression_axis,
        ((pdcd1_z + lag3_z) / 2.0)
            AS exhaustion_score,
        ((cd8a_z + ifng_z) *
         (pdcd1_z + lag3_z + cd274_z)
        ) AS composite_ici_score
FROM 
    normalized
),
risk_model AS (
SELECT
        *,
        NTILE(4) OVER (
            ORDER BY survival_time ASC
        ) AS survival_risk_quartile
FROM
    features
),
phenotypes AS (
    SELECT
        *,
        CASE
         WHEN immune_activation_axis >= 0
            AND immune_suppression_axis >= 0
            AND survival_risk_quartile = 1
        THEN 'AGGRESSIVE_HOT_RESTRAINED'
        WHEN immune_activation_axis >= 0 AND immune_suppression_axis >= 0
        THEN 'HOT_RESTRAINED'
        WHEN immune_activation_axis >= 0 AND immune_suppression_axis < 0
        THEN 'INFLAMED_ACTIVE'
        WHEN immune_activation_axis < 0 AND immune_suppression_axis >= 0
        THEN 'EXHAUSTED_COLD'
        ELSE 'IMMUNE_DESERT'
    END AS tumour_immune_state
FROM 
    risk_model
)
SELECT
    patient_id,
    survival_time,
    survival_status,
    ROUND(CAST(immune_activation_axis AS numeric), 3)
        AS immune_activation_axis,
    ROUND(CAST(immune_suppression_axis AS numeric), 3)
        AS immune_suppression_axis,
    ROUND(CAST(exhaustion_score AS numeric), 3)
        AS exhaustion_score,
    ROUND(CAST(composite_ici_score AS numeric), 3)
        AS composite_ici_score,
    survival_risk_quartile,
    tumour_immune_state
FROM 
    phenotypes
ORDER BY
    composite_ici_score DESC;