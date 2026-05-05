WITH checkpoint_inhibitors AS (
    SELECT
    survival.patient_id,
    survival_status,
    survival_time,
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
    checkpoint_inhibitors
WHERE 
    cd8a_expression IS NOT NULL
    AND ifng_expression IS NOT NULL
    AND pdcd1_expression IS NOT NULL
    AND lag3_expression IS NOT NULL
    AND cd274_expression IS NOT NULL
),
normalized AS (
SELECT
    checkpoint_inhibitors.*,
    (cd8a_expression - mean_cd8a) / NULLIF(sd_cd8a, 0) AS cd8a_z,
    (ifng_expression - mean_ifng) / NULLIF(sd_ifng, 0) AS ifng_z,
    (pdcd1_expression - mean_pdcd1) / NULLIF(sd_pdcd1, 0) AS pdcd1_z,
    (lag3_expression - mean_lag3) / NULLIF(sd_lag3, 0) AS lag3_z,
    (cd274_expression - mean_cd274) / NULLIF(sd_cd274, 0) AS cd274_z
FROM 
    checkpoint_inhibitors
CROSS JOIN stats
),
scores AS (
SELECT *,
    cd8a_z AS immune_presence_score,
    ifng_z AS functional_score,
    (pdcd1_z + lag3_z) / 2.0 AS exhaustion_score,
    cd274_z AS tumour_suppression_score
FROM 
    normalized
),
composite AS (
SELECT *,
    (immune_presence_score + functional_score) *
    (exhaustion_score + tumour_suppression_score) 
    AS ici_score
FROM 
    scores
),
final_stratification AS (
SELECT *,
    NTILE(3) OVER (ORDER BY ici_score DESC) AS ici_tile
FROM 
composite
)
SELECT
    patient_id,
    survival_status,
    survival_time,
    ici_score,
    CASE 
        WHEN ici_tile = 1 THEN 'high_response_likelihood'
        WHEN ici_tile = 2 THEN 'intermediate_response'
        ELSE 'low_response_likelihood'
    END AS ici_response_group
FROM 
    final_stratification
ORDER BY
    survival_status DESC,
    survival_time DESC,
    ici_score DESC;


 