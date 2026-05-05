SELECT 
    age,
    COUNT(DISTINCT SUBSTRING(patient_id, 1, 12)) AS patient_count
FROM phenotype
WHERE age IS NOT NULL AND age > 1
GROUP BY age
ORDER BY patient_count DESC;


/*The dataset represents a patient population heavily skewed toward older adults, 
with a median age of approximately 66 and a total count of 501 individuals. 
The vast majority of patients (87%) fall within the 50-to-79-year-old range, 
peaking specifically between ages 60 and 74. Conversely, there is minimal 
representation of patients under 40 or over 85, suggesting these insights are 
most applicable to geriatric care or chronic conditions typically managed in late middle age and retiremnte.*/
