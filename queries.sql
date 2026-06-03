-- ============================================================
-- Olist E-Commerce Customer & Revenue Analytics
-- Dataset: Brazilian E-Commerce Public Dataset (Kaggle)
-- Author: Dharmik Bhut
-- ============================================================
-- Tables used:
--   customers, orders, order_items, order_payments,
--   products, category_translation
-- ============================================================


-- ============================================================
-- Q1: Which customers generate the most revenue?
--     Uses: JOIN, GROUP BY, aggregation, ORDER BY
-- ============================================================

SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    ROUND(SUM(p.payment_value), 2)    AS total_revenue,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    ROUND(AVG(p.payment_value), 2)     AS avg_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- Q2: What is the repeat purchase rate?
--     Uses: CTE, conditional aggregation
-- ============================================================

WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                                                          AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)                                 AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                                                                 AS repeat_rate_pct
FROM customer_order_counts;

-- Result: 3.0% repeat rate — most customers only purchase once.
-- Business insight: strong opportunity for email re-engagement campaigns.


-- ============================================================
-- Q3: Which product categories are growing fastest?
--     Uses: CTE, Window Function (LAG), calculated growth %
-- ============================================================

WITH monthly_sales AS (
    SELECT
        ct.product_category_name_english   AS category,
        STRFTIME('%Y-%m', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price), 2)            AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category, month
),
month_over_month AS (
    SELECT
        category,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY category ORDER BY month) AS prev_month_revenue
    FROM monthly_sales
),
growth_rates AS (
    SELECT
        category,
        month,
        revenue,
        prev_month_revenue,
        ROUND(
            100.0 * (revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0), 2
        ) AS growth_pct
    FROM month_over_month
    WHERE prev_month_revenue IS NOT NULL
)
SELECT
    category,
    ROUND(AVG(growth_pct), 2) AS avg_monthly_growth_pct
FROM growth_rates
GROUP BY category
ORDER BY avg_monthly_growth_pct DESC
LIMIT 10;


-- ============================================================
-- Q4: What is Customer Lifetime Value (CLV)?
--     Uses: CTE, aggregation
-- ============================================================

WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        ROUND(SUM(p.payment_value), 2)   AS total_spend,
        COUNT(DISTINCT o.order_id)        AS num_orders,
        MIN(o.order_purchase_timestamp)   AS first_order_date,
        MAX(o.order_purchase_timestamp)   AS last_order_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                  AS total_customers,
    ROUND(AVG(total_spend), 2)                AS avg_clv,
    ROUND(AVG(num_orders), 2)                 AS avg_orders_per_customer,
    ROUND(MIN(total_spend), 2)                AS min_clv,
    ROUND(MAX(total_spend), 2)                AS max_clv,
    ROUND(
        SUM(CASE WHEN total_spend > 500 THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2
    )                                         AS pct_high_value_customers
FROM customer_spending;

-- Result: avg CLV = $165.20 | max = $13,664 | avg orders = 1.03


-- ============================================================
-- Q5: Monthly revenue trends
--     Uses: STRFTIME date grouping, aggregation
-- ============================================================

SELECT
    STRFTIME('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 2)                AS total_revenue,
    COUNT(DISTINCT o.order_id)                     AS total_orders,
    COUNT(DISTINCT c.customer_unique_id)           AS unique_customers,
    ROUND(AVG(p.payment_value), 2)                 AS avg_order_value
FROM orders o
JOIN order_payments p
    ON o.order_id = p.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY month
ORDER BY month;

-- Peak: Nov 2017 ($1.15M) — likely Black Friday effect
-- Growth: Jan 2017 → Jan 2018 revenue grew ~8x


-- ============================================================
-- Q6: Top 20% customer revenue contribution (Pareto Analysis)
--     Uses: Window Function (NTILE), CTE, aggregation
-- ============================================================

WITH customer_revenue AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spend
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
quintile_buckets AS (
    SELECT
        customer_unique_id,
        total_spend,
        NTILE(5) OVER (ORDER BY total_spend DESC) AS quintile
    FROM customer_revenue
),
totals AS (
    SELECT SUM(total_spend) AS grand_total FROM quintile_buckets
)
SELECT
    qb.quintile,
    CASE qb.quintile
        WHEN 1 THEN 'Top 20%'
        WHEN 2 THEN '21–40%'
        WHEN 3 THEN '41–60%'
        WHEN 4 THEN '61–80%'
        WHEN 5 THEN 'Bottom 20%'
    END                                               AS customer_segment,
    COUNT(*)                                          AS num_customers,
    ROUND(SUM(qb.total_spend), 2)                     AS segment_revenue,
    ROUND(100.0 * SUM(qb.total_spend) / t.grand_total, 2) AS revenue_share_pct
FROM quintile_buckets qb
CROSS JOIN totals t
GROUP BY qb.quintile
ORDER BY qb.quintile;

-- Result: Top 20% of customers → 53.5% of revenue (Pareto rule confirmed)


-- ============================================================
-- BONUS: Cohort Analysis — New customers by first purchase month
--     Uses: CTE, MIN aggregation, STRFTIME
-- ============================================================

WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        STRFTIME('%Y-%m', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    cohort_month,
    COUNT(*) AS new_customers
FROM first_purchase
WHERE cohort_month >= '2017-01'
GROUP BY cohort_month
ORDER BY cohort_month;


-- ============================================================
-- BONUS: Top 10 categories by total revenue
--     Uses: JOIN across 4 tables, GROUP BY, ORDER BY
-- ============================================================

SELECT
    ct.product_category_name_english   AS category,
    ROUND(SUM(oi.price), 2)            AS total_revenue,
    COUNT(DISTINCT oi.order_id)        AS total_orders,
    ROUND(AVG(oi.price), 2)            AS avg_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;
