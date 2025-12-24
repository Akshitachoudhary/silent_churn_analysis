CREATE DATABASE churn_analysis;

DROP TABLE IF EXISTS churn_data;
CREATE TABLE churn_data (
    user_id SERIAL PRIMARY KEY,
    age INT,
    gender VARCHAR(10),
    region_category VARCHAR(50),
    joining_date DATE,
    api_calls_90d INT,
    session_minutes_90d NUMERIC,
    days_since_active INT
);


COPY churn_data(age, gender, region_category, joining_date,
                api_calls_90d, session_minutes_90d, days_since_active)
FROM 'C:\Users\akshi\OneDrive\Desktop\DA\churn_data_clean.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM churn_data LIMIT 5;

--Checking missing values
SELECT
    COUNT(*) FILTER (WHERE api_calls_90d IS NULL) AS missing_api,
    COUNT(*) FILTER (WHERE session_minutes_90d IS NULL) AS missing_sessions,
    COUNT(*) FILTER (WHERE days_since_active IS NULL) AS missing_days
FROM churn_data;

--Understanding engagement distribution
SELECT
    MIN(session_minutes_90d),
    MAX(session_minutes_90d),
    AVG(session_minutes_90d)
FROM churn_data;

SELECT
    MIN(api_calls_90d),
    MAX(api_calls_90d),
    AVG(api_calls_90d)
FROM churn_data;

-- Defining Engagement Thresholds (using median)
CREATE VIEW churn_medians AS
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_minutes_90d) AS session_median,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY api_calls_90d) AS api_median
FROM churn_data;


/*Silent Churn Logic: A user is silently churned if
-days_since_active > 14
-session_minutes_90d < median
-api_calls_90d < median  */

CREATE VIEW churn_classification AS
SELECT
    d.*,
    CASE
        WHEN d.days_since_active > 14
         AND d.session_minutes_90d < m.session_median
         AND d.api_calls_90d < m.api_median
        THEN 'Silent Churn'
        ELSE 'Active'
    END AS churn_status
FROM churn_data d
CROSS JOIN churn_medians m;

--Count of silently churned users

SELECT
    churn_status,
    COUNT(*) AS users
FROM churn_classification
GROUP BY churn_status;

-- REGION WISE SILENT CHURN
SELECT
    region_category,
    churn_status,
    COUNT(*) AS users
FROM churn_classification
GROUP BY region_category, churn_status
ORDER BY region_category;

--VALIDATION METRICS
SELECT
    churn_status,
    AVG(days_since_active) AS avg_days_inactive,
    AVG(session_minutes_90d) AS avg_sessions,
    AVG(api_calls_90d) AS avg_api
FROM churn_classification
GROUP BY churn_status;

--EARLY WARNING 
SELECT
    churn_status,
    MIN(days_since_active) AS min_inactive,
    MAX(days_since_active) AS max_inactive
FROM churn_classification
GROUP BY churn_status;