# Clinical Data Platform Ingestion & Quality Pipeline

## Project Overview

This project simulates a Clinical Data Platform ingestion pipeline designed to ingest, validate, and analyze raw healthcare dataset records. Mirroring the daily responsibilities of a Business Analyst II on the Data Platform team at Cohere Health, this initiative translates healthcare business requirements into high-quality data engineering pipelines using PostgreSQL.

---

## 📋 Agile Framework & User Stories

To ensure this platform serves actual clinical and operational needs, development was driven by the following Agile requirements:

* **Epic:** Clinical Prior Authorization & Claims Validation
* **User Story:**
> *“As a Clinical Claims Auditor, I want to automatically validate ingested patient admission and discharge data so that we can flag logical errors (such as negative billing or invalid date sequences) before sending data to the downstream prior-authorization engine.”*



---

## 🗺️ Source-to-Target Mapping (STTM)

The raw dataset was mapped to our standardized PostgreSQL platform target schema using the following data definitions and business requirements:

| Source Field (Kaggle CSV) | Target Field (Postgres) | Data Type | Business Validation Rules |
| --- | --- | --- | --- |
| `Name` | `patient_name` | `VARCHAR(100)` | Standardize names; check for nulls. |
| `Date_of_Admission` | `admission_date` | `DATE` | Must be a valid date format. |
| `Discharge_Date` | `discharge_date` | `DATE` | Must be greater than or equal to `admission_date`. |
| `Billing_Amount` | `billing_amount` | `DECIMAL(10,2)` | Must be a positive number greater than 0.00. |
| `Medical_Condition` | `diagnosis` | `VARCHAR(100)` | Profile string values for downstream analytics. |

---

## 🛠️ PostgreSQL Implementation

### 1. Target Schema Creation

```sql
CREATE TABLE kaggle_healthcare_data (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(10),
    Blood_Type VARCHAR(5),
    Medical_Condition VARCHAR(100),
    Date_of_Admission DATE,
    Doctor VARCHAR(100),
    Hospital VARCHAR(100),
    Insurance_Provider VARCHAR(100),
    Billing_Amount DECIMAL(10, 2),
    Room_Number INT,
    Admission_Type VARCHAR(50),
    Discharge_Date DATE,
    Medication VARCHAR(100),
    Test_Results VARCHAR(50)
);

```

### 2. Client-Side Data Ingestion (PSQL)

```sql
\copy kaggle_healthcare_data FROM '/Users/koushi_reddy/Downloads/healthcare_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

```

---

## 🔍 Data Quality & Analytical SQL Queries

### Query 1: High-Level Platform Profile Check

Verifies total record counts and patient age ranges to ensure data completeness during initial ingestion.

```sql
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT Name) AS unique_patient_names,
    MIN(Age) AS youngest_patient_age,
    MAX(Age) AS oldest_patient_age
FROM kaggle_healthcare_data;

```

### Query 2: Clinical Logical Validation

This query automatically flags "dirty data" points that violate business logic—such as patients discharged before they were admitted, or negative/zero hospital bills.

```sql
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

```

### Query 3: Payer & Diagnosis Financial Segmentation

Provides average and total billing metrics split by insurance carrier and medical condition to optimize financial operations.

```sql
SELECT 
    Insurance_Provider,
    Medical_Condition,
    COUNT(*) AS total_cases,
    ROUND(AVG(Billing_Amount), 2) AS average_bill,
    ROUND(SUM(Billing_Amount), 2) AS total_gross_billing
FROM kaggle_healthcare_data
GROUP BY Insurance_Provider, Medical_Condition
ORDER BY Insurance_Provider, average_bill DESC;

```

---

## 📊 Power BI Executive Dashboard Architecture

To translate our validated data into actionable business intelligence, an operational dashboard was developed in Power BI utilizing DAX for specialized metrics.

### 1. Data Quality Business Logic (DAX)
A calculated column was established to monitor data ingestion compliance natively within the reporting layer:
```dax
Data Quality Status = 
IF(
    'kaggle_healthcare_data'[Discharge_Date] < 'kaggle_healthcare_data'[Date_of_Admission], 
    "FAIL: Invalid Dates",
    IF(
        'kaggle_healthcare_data'[Billing_Amount] <= 0, 
        "FAIL: Invalid Billing", 
        "PASS"
    )
)
