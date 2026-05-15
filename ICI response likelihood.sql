WITH immune_gene_matrix AS (
    SELECT
        survival.patient_id,
        survival.survival_time,
        survival.survival_status,
        AVG(CASE 
            WHEN gene_map.gene_name = 'CD8A' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'GZMB' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'IFNG' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'PRF1' THEN gene_expression.expression
        END) AS immune_activation_strength,
        AVG(CASE 
            WHEN gene_map.gene_name = 'PDCD1' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'CD274' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'CTLA4' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'LAG3' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'TIGIT' THEN gene_expression.expression
        END) AS immune_checkpoint_suppression_strength,
        AVG(CASE 
            WHEN gene_map.gene_name = 'TOX' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'EOMES' THEN gene_expression.expression
            WHEN gene_map.gene_name = 'HAVCR2' THEN gene_expression.expression
        END) AS immune_exhaustion_pressure
    FROM 
        survival
    JOIN gene_expression ON survival.patient_id = gene_expression.patient_id
    JOIN gene_map ON gene_map.gene_id = gene_expression.gene
    GROUP BY
        survival.patient_id,
        survival.survival_time,
        survival.survival_status
),
immune_geometry AS (
    SELECT
        patient_id,
        survival_time,
        survival_status,
        immune_activation_strength,
        immune_checkpoint_suppression_strength,
        immune_exhaustion_pressure,
        (immune_activation_strength - immune_checkpoint_suppression_strength) AS immune_effector_balance,
        (immune_activation_strength + immune_checkpoint_suppression_strength) AS immune_system_activity_load,
        (immune_exhaustion_pressure - immune_activation_strength) AS immune_dysfunction_gap,
        CASE
            WHEN immune_activation_strength > immune_checkpoint_suppression_strength
                 AND immune_exhaustion_pressure < immune_activation_strength
            THEN 'activation_dominant_effective_immunity'
            WHEN immune_activation_strength > immune_checkpoint_suppression_strength
                 AND immune_exhaustion_pressure >= immune_activation_strength
            THEN 'activation_dominant_exhausted_immunity'
            WHEN immune_checkpoint_suppression_strength > immune_activation_strength
            THEN 'suppression_dominant_immune_blockade'
            ELSE 'balanced_immune_state'
        END AS immune_state
    FROM 
        immune_gene_matrix
)
SELECT
    immune_state,
    COUNT(*) AS number_of_samples,
    AVG(survival_time) AS mean_survival_time,
    CAST(SUM(CASE WHEN survival_status = 1 THEN 1 ELSE 0 END) AS DOUBLE PRECISION)
    / COUNT(*) AS mortality_rate
FROM 
    immune_geometry
GROUP BY 
    immune_state
ORDER BY 
    mortality_rate DESC;