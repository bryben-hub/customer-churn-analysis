-- CUSTOMER CHURN ANALYSIS QUERIES
-- These are the queries you'll be asked in interviews

-- 1. Calculate monthly churn rate
WITH monthly_cohorts AS (
  SELECT 
    DATE_TRUNC('month', signup_date) AS cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN churned = 1 THEN customer_id END) AS churned_customers
  FROM customers
  GROUP BY 1
)
SELECT 
  cohort_month,
  cohort_size,
  churned_customers,
  ROUND(churned_customers::DECIMAL / cohort_size * 100, 2) AS churn_rate
FROM monthly_cohorts
ORDER BY cohort_month DESC;

-- 2. Revenue impact analysis
SELECT 
  CASE 
    WHEN churned = 1 THEN 'Lost'
    ELSE 'Retained'
  END AS customer_status,
  COUNT(*) AS customer_count,
  ROUND(AVG(monthly_spend), 2) AS avg_monthly_spend,
  ROUND(SUM(monthly_spend), 2) AS total_monthly_revenue,
  ROUND(SUM(monthly_spend) * 12, 2) AS annual_revenue_impact
FROM customers
GROUP BY 1;

-- 3. Identify high-value at-risk customers
WITH customer_metrics AS (
  SELECT 
    customer_id,
    monthly_spend,
    last_login_days_ago,
    support_tickets,
    CASE 
      WHEN last_login_days_ago > 30 THEN 'High Risk'
      WHEN last_login_days_ago > 14 THEN 'Medium Risk'
      ELSE 'Low Risk'
    END AS risk_level
  FROM customers
  WHERE churned = 0  -- Only current customers
)
SELECT 
  risk_level,
  COUNT(*) AS customer_count,
  ROUND(AVG(monthly_spend), 2) AS avg_spend,
  ROUND(SUM(monthly_spend), 2) AS total_revenue_at_risk
FROM customer_metrics
GROUP BY risk_level
ORDER BY 
  CASE risk_level
    WHEN 'High Risk' THEN 1
    WHEN 'Medium Risk' THEN 2
    ELSE 3
  END;

-- 4. Cohort retention analysis (CRITICAL for interviews)
WITH cohort_data AS (
  SELECT 
    customer_id,
    DATE_TRUNC('month', signup_date) AS cohort_month,
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, signup_date)) AS months_since_signup,
    churned
  FROM customers
)
SELECT 
  cohort_month,
  months_since_signup,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(DISTINCT CASE WHEN churned = 0 THEN customer_id END) AS retained,
  ROUND(COUNT(DISTINCT CASE WHEN churned = 0 THEN customer_id END)::DECIMAL 
        / COUNT(DISTINCT customer_id) * 100, 2) AS retention_rate
FROM cohort_data
GROUP BY cohort_month, months_since_signup
ORDER BY cohort_month, months_since_signup;

-- 5. Support ticket correlation
SELECT 
  CASE 
    WHEN support_tickets = 0 THEN '0 tickets'
    WHEN support_tickets BETWEEN 1 AND 2 THEN '1-2 tickets'
    WHEN support_tickets BETWEEN 3 AND 5 THEN '3-5 tickets'
    ELSE '6+ tickets'
  END AS ticket_bucket,
  COUNT(*) AS customers,
  ROUND(AVG(churned) * 100, 2) AS churn_rate,
  ROUND(AVG(monthly_spend), 2) AS avg_spend
FROM customers
GROUP BY ticket_bucket
ORDER BY 
  CASE ticket_bucket
    WHEN '0 tickets' THEN 1
    WHEN '1-2 tickets' THEN 2
    WHEN '3-5 tickets' THEN 3
    ELSE 4
  END;
