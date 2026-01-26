Q1 — Total boxes shipped
SELECT SUM(boxes_shipped) AS total_boxes_shipped
FROM fact_sales;

Q2 — Monthly shipment trend
SELECT
  DATE_TRUNC('month', sale_date)::date AS month,
  SUM(boxes_shipped) AS boxes_shipped
FROM fact_sales
GROUP BY month
ORDER BY month;

Q3 — Top products by volume
SELECT
  product_id,
  SUM(boxes_shipped) AS total_boxes
FROM fact_sales
GROUP BY product_id
ORDER BY total_boxes DESC
LIMIT 5;

Q4 — Sales channel performance
SET search_path TO choco;

SELECT
  sc.sales_channel_name,
  SUM(fs.boxes_shipped) AS total_boxes
FROM fact_sales fs
JOIN dim_sales_channel sc
  ON sc.sales_channel_id = fs.sales_channel_id
GROUP BY sc.sales_channel_name
ORDER BY total_boxes DESC;

Q5 — Delivery success distribution

SELECT
  ds.delivery_status_name,
  COUNT(*) AS orders
FROM fact_sales fs
JOIN dim_delivery_status ds
  ON ds.delivery_status_id = fs.delivery_status_id
GROUP BY ds.delivery_status_name;


Q6 — On-time delivery percentage
SELECT
  ROUND(
    100.0 * SUM(CASE WHEN ds.delivery_status_name = 'Completed' THEN 1 ELSE 0 END)
    / COUNT(*),
    2
  ) AS on_time_delivery_pct
FROM fact_sales fs
JOIN dim_delivery_status ds
  ON ds.delivery_status_id = fs.delivery_status_id;


Q7 — Salesperson performance ranking
SELECT
  salesperson_id,
  SUM(boxes_shipped) AS total_boxes,
  RANK() OVER (ORDER BY SUM(boxes_shipped) DESC) AS rank
FROM fact_sales
GROUP BY salesperson_id;

Q8 — Location demand leaderboard
SELECT
  location_id,
  SUM(boxes_shipped) AS total_boxes
FROM fact_sales
GROUP BY location_id
ORDER BY total_boxes DESC;

Q9 — Channel × product distribution matrix
SET search_path TO choco;

SELECT
  sc.sales_channel_name,
  fs.product_id,
  SUM(fs.boxes_shipped) AS boxes_shipped
FROM fact_sales fs
JOIN dim_sales_channel sc
  ON sc.sales_channel_id = fs.sales_channel_id
GROUP BY sc.sales_channel_name, fs.product_id
ORDER BY sc.sales_channel_name, boxes_shipped DESC;

Q10 — Peak shipping days
SELECT
  sale_date,
  SUM(boxes_shipped) AS boxes_shipped
FROM fact_sales
GROUP BY sale_date
ORDER BY boxes_shipped DESC
LIMIT 10;
