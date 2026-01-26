Q1. Attrition rate by department

SELECT
    department,
    COUNT(*) AS employees,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers,
    ROUND(
        100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC;

Q2. Attrition vs overtime

SELECT
    over_time,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
    ROUND(
        SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END)::numeric
        / COUNT(*) * 100,
        2
    ) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY over_time
ORDER BY attrition_rate_pct DESC;

Q3.Pay vs attrition (are leavers underpaid?)

SELECT
    attrition,
    ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM technova.employee_attrition
GROUP BY attrition;

Q4. High-risk employee segments

SELECT
    job_role,
    COUNT(*) AS employees,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS leavers
FROM technova.employee_attrition
GROUP BY job_role
HAVING COUNT(*) >= 20
ORDER BY leavers DESC;

Q5 — Attrition rate by department (ranked)

SELECT
  department,
  COUNT(*) AS employees,
  SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
  ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC, employees DESC;

Q6 — Attrition by Over Time + Work-Life Balance (risk view)

SELECT
  over_time,
  work_life_balance,
  COUNT(*) AS employees,
  SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
  ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY over_time, work_life_balance
ORDER BY attrition_rate_pct DESC, employees DESC;

Q7 — Pay fairness signal: Attrition by salary band + job level

SELECT
  job_level,
  CASE
    WHEN monthly_income < 3000 THEN '<3k'
    WHEN monthly_income < 6000 THEN '3k-6k'
    WHEN monthly_income < 10000 THEN '6k-10k'
    ELSE '10k+'
  END AS income_band,
  COUNT(*) AS employees,
  SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
  ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY job_level, income_band
ORDER BY job_level, attrition_rate_pct DESC;

Q8 — "Top risk profiles" (filters + ranking for action)

WITH base AS (
  SELECT
    department,
    job_role,
    over_time,
    COUNT(*) AS employees,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions
  FROM technova.employee_attrition
  GROUP BY department, job_role, over_time
)
SELECT
  department,
  job_role,
  over_time,
  employees,
  attritions,
  ROUND(100.0 * attritions / employees, 2) AS attrition_rate_pct
FROM base
WHERE employees >= 10
ORDER BY attrition_rate_pct DESC, employees DESC
LIMIT 15;

Q9) Early-leaver analysis: attrition by years at company band

WITH tenure_base AS (
  SELECT
    CASE
      WHEN years_at_company < 1 THEN '<1 year'
      WHEN years_at_company BETWEEN 1 AND 2 THEN '1–2 years'
      WHEN years_at_company BETWEEN 3 AND 5 THEN '3–5 years'
      WHEN years_at_company BETWEEN 6 AND 10 THEN '6–10 years'
      ELSE '10+ years'
    END AS tenure_band,
    attrition
  FROM technova.employee_attrition
)
SELECT
  tenure_band,
  COUNT(*) AS employees,
  SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
  ROUND(
    100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS attrition_rate_pct
FROM tenure_base
GROUP BY tenure_band
ORDER BY
  CASE tenure_band
    WHEN '<1 year' THEN 1
    WHEN '1–2 years' THEN 2
    WHEN '3–5 years' THEN 3
    WHEN '6–10 years' THEN 4
    ELSE 5
  END;

Q10) Promotion stagnation: years since last promotion vs attrition

SELECT
  years_since_last_promotion,
  COUNT(*) AS employees,
  SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attritions,
  ROUND(100.0 * SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attrition_rate_pct
FROM technova.employee_attrition
GROUP BY years_since_last_promotion
ORDER BY years_since_last_promotion;
