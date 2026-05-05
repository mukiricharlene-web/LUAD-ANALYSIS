CREATE TABLE gene_expression (
    patient_id TEXT,
    gene TEXT,
    expression FLOAT
);

CREATE TABLE phenotype (
    patient_id TEXT,
    age INT,
    gender TEXT,
    cancer_stage VARCHAR (100)
);

CREATE TABLE survival (
    patient_id TEXT,
    survival_time FLOAT,
    survival_status INT
);

CREATE TABLE gene_map (
    gene_id TEXT,
    gene_name TEXT
);


\copy gene_expression( gene, patient_id, expression) FROM 'C:\LUAD\gene_expression_long.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy phenotype(patient_id, age, gender, cancer_stage) FROM 'C:\LUAD\phenotype.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy survival(patient_id, survival_time, survival_status) FROM 'C:/LUAD/survival_clean.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy gene_map(gene_id, gene_name) FROM 'C:\LUAD\Gene_ID.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');


ALTER TABLE phenotype ALTER COLUMN age TYPE NUMERIC;


