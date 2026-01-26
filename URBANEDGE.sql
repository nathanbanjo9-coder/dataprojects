1) Campaign ROAS leaderboard (using the view)

SELECT campaign_id, campaign_name, brand_name, budget_usd, revenue_usd, roas
FROM urbanedge_retail.vw_campaign_kpis
ORDER BY roas DESC NULLS LAST
LIMIT 10;

2) Month-over-month revenue + MoM % change (window function)

WITH m AS (
  SELECT date_trunc('month', perf_date)::date AS month,
         SUM(revenue_usd) AS revenue
  FROM urbanedge_retail.fact_post_performance
  GROUP BY 1
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
       ROUND(
         (revenue - LAG(revenue) OVER (ORDER BY month))
         / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2
       ) AS mom_pct
FROM m
ORDER BY month;

3) Best platform by ROAS (budget-weighted)

SELECT pl.platform_name,
       SUM(k.revenue_usd) AS revenue,
       SUM(k.budget_usd)  AS budget,
       ROUND(SUM(k.revenue_usd)/NULLIF(SUM(k.budget_usd),0), 4) AS roas
FROM urbanedge_retail.vw_campaign_kpis k
JOIN urbanedge_retail.fact_campaign c ON c.campaign_id = k.campaign_id
JOIN urbanedge_retail.bridge_campaign_influencer bci ON bci.campaign_id = c.campaign_id
JOIN urbanedge_retail.dim_influencer i ON i.influencer_id = bci.influencer_id
JOIN urbanedge_retail.dim_platform pl ON pl.platform_id = i.platform_id
GROUP BY 1
ORDER BY roas DESC NULLS LAST;

4) Influencer ROI multiple + rank within platform

SELECT influencer_id, influencer_name, platform_name,
       attributed_revenue_usd, gross_paid_usd, roi_multiple,
       DENSE_RANK() OVER (PARTITION BY platform_name ORDER BY roi_multiple DESC NULLS LAST) AS platform_rank
FROM urbanedge_retail.vw_influencer_roi
ORDER BY platform_name, platform_rank;

4) Influencer ROI multiple + rank within platform

SELECT influencer_id, influencer_name, platform_name,
       attributed_revenue_usd, gross_paid_usd, roi_multiple,
       DENSE_RANK() OVER (PARTITION BY platform_name ORDER BY roi_multiple DESC NULLS LAST) AS platform_rank
FROM urbanedge_retail.vw_influencer_roi
ORDER BY platform_name, platform_rank;

5) Content type effectiveness (conversion rate + revenue per 1k views)

SELECT p.content_type,
       SUM(pp.conversions) AS conversions,
       SUM(pp.views) AS views,
       ROUND(SUM(pp.conversions)::numeric / NULLIF(SUM(pp.link_clicks),0), 4) AS conv_rate,
       ROUND(SUM(pp.revenue_usd) / NULLIF(SUM(pp.views),0) * 1000, 2) AS revenue_per_1k_views
FROM urbanedge_retail.fact_post p
JOIN urbanedge_retail.fact_post_performance pp ON pp.post_id = p.post_id
GROUP BY 1
ORDER BY revenue_per_1k_views DESC NULLS LAST;

6) Performance decay after posting (day offset analysis)

WITH base AS (
  SELECT p.post_id,
         (pp.perf_date - p.post_date) AS day_offset,
         pp.views,
         pp.revenue_usd
  FROM urbanedge_retail.fact_post p
  JOIN urbanedge_retail.fact_post_performance pp ON pp.post_id = p.post_id
)
SELECT day_offset,
       AVG(views) AS avg_views,
       AVG(revenue_usd) AS avg_revenue
FROM base
GROUP BY 1
ORDER BY 1;


7) "Overspend alert": high budget + low ROAS

SELECT campaign_id, campaign_name, brand_name, budget_usd, revenue_usd, roas
FROM urbanedge_retail.vw_campaign_kpis
WHERE budget_usd >= 20000
  AND (roas IS NULL OR roas < 1.0)
ORDER BY budget_usd DESC;

8) Payment exposure: pending amounts by brand

SELECT b.brand_name,
       SUM(pay.net_amount_usd) AS pending_net_amount
FROM urbanedge_retail.fact_payment pay
JOIN urbanedge_retail.bridge_campaign_influencer bci ON bci.campaign_influencer_id = pay.campaign_influencer_id
JOIN urbanedge_retail.fact_campaign c ON c.campaign_id = bci.campaign_id
JOIN urbanedge_retail.dim_brand b ON b.brand_id = c.brand_id
WHERE pay.payment_status = 'pending'
GROUP BY 1
ORDER BY pending_net_amount DESC;
