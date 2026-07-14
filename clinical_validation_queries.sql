-- =========================================================================
-- PROJECT: Clinical Data Platform Ingestion & Quality Pipeline
-- ROLE: Business Analyst
-- DESCRIPTION: Standardized queries used to profile, audit, and analyze 
--              newly ingested healthcare dataset records.
-- =========================================================================

-- -------------------------------------------------------------------------
-- QUERY 1: High-Level Platform Profile Check
-- Purpose: Verifies successful data volume transfer and identifies basic demographics.
-- -------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT Name) AS unique_patient_names,
    MIN(Age) AS youngest_patient_age,
    MAX(Age) AS oldest_patient_age
FROM kaggle_healthcare_data;


-- -------------------------------------------------------------------------
-- QUERY 2: Data Quality & Clinical Logical Validation
-- Purpose: Implements healthcare business logic to flag data anomalies 
--          (mismatched dates or invalid negative billing).
-- -------------------------------------------------------------------------
SELECT 
    Name,
    Date_of_Admission,
    Discharge_Date,
    Billing_Amount,
    CASE 
        WHEN Discharge_Date < Date_of_Admission THEN 'FAIL: Discharge date before admission'
        WHEN Billing_Amount <= 0 THEN 'FAIL: Invalid/Negative billing amount'
        ELSE 'PASS'
    END AS data_quality_status
FROM kaggle_healthcare_data
WHERE Discharge_Date < Date_of_Admission 
   OR Billing_Amount <= 0;


-- -------------------------------------------------------------------------
-- QUERY 3: Payer & Diagnosis Financial Segmentation
-- Purpose: Extracts operational trends showing which combinations of conditions 
--          and insurance providers represent the highest financial volume.
-- -------------------------------------------------------------------------
SELECT 
    Insurance_Provider,
    Medical_Condition,
    COUNT(*) AS total_cases,
    ROUND(AVG(Billing_Amount), 2) AS average_bill,
    ROUND(SUM(Billing_Amount), 2) AS total_gross_billing
FROM kaggle_healthcare_data
GROUP BY Insurance_Provider, Medical_Condition
ORDER BY Insurance_Provider, average_bill DESC;
