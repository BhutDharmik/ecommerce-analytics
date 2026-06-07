# Olist E-Commerce Customer & Revenue Analytics

> **Tools:** SQL (SQLite) · Tableau
> **Dataset:** [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
> **Skills demonstrated:** CTEs · Window Functions · Multi-table Joins · Cohort Analysis · Data Visualization

---

## Project Overview

This project analyzes **~100,000 orders** from Olist, a Brazilian e-commerce marketplace, to answer common business questions around customer behavior, revenue trends, and product performance. The goal was to simulate the kind of analysis a data analyst would do at a real company — turning raw transactional data into actionable insights.

SQL was used to query and engineer all KPIs. A Tableau dashboard was built on top of the results to surface findings visually.

---

## Dataset

The dataset contains 9 tables covering the full order lifecycle:

| Table | Description |
|---|---|
| `customers` | Customer IDs, city, and state |
| `orders` | Order status and timestamps |
| `order_items` | Products per order, price, freight |
| `order_payments` | Payment method and value |
| `order_reviews` | Review scores and comments |
| `products` | Product dimensions and category |
| `sellers` | Seller location info |
| `geolocation` | ZIP code lat/lng mapping |
| `category_translation` | Portuguese → English category names |

---

## Business Questions Answered

### 1. Which customers generate the most revenue?
Joined `customers`, `orders`, and `order_payments` to calculate total spend per `customer_unique_id`. Used `GROUP BY` and `ORDER BY` to rank top 20 customers by lifetime revenue.

**Finding:** The top customer spent **$13,664** across multiple orders — over 80x the average customer.

---

### 2. What is the repeat purchase rate?
Used a CTE to count orders per unique customer, then calculated the percentage with more than one order.

**Finding:** Only **3.0%** of customers (2,801 out of 93,358) made more than one purchase — a major retention opportunity.

---

### 3. Which product categories are growing fastest?
Used `LAG()` window function to compare each category's monthly revenue to the prior month, then averaged the growth rates.

**Finding:** `construction_tools_safety` had the highest average monthly growth (+987%), followed by `fashion_bags_accessories` (+737%).

---

### 4. What is Customer Lifetime Value (CLV)?
Aggregated total spend and order count per unique customer.

| Metric | Value |
|---|---|
| Average CLV | $165.20 |
| Median orders per customer | 1.03 |
| Max CLV | $13,664.08 |
| Total unique customers | 93,357 |

**Finding:** The low average orders-per-customer (1.03) confirms most customers are one-time buyers. A loyalty program targeting customers with 1 order could meaningfully improve CLV.

---

### 5. Monthly revenue trends
Grouped orders by `STRFTIME('%Y-%m', order_purchase_timestamp)` to see revenue by month.

**Finding:** Revenue grew roughly **8x from Jan 2017 to Jan 2018**. A spike in **November 2017 ($1.15M)** was likely driven by Black Friday. Revenue stabilized around **$1M/month** throughout 2018.

---

### 6. Do the top 20% of customers drive 80% of revenue? (Pareto Analysis)
Used `NTILE(5)` window function to bucket customers into revenue quintiles, then measured each group's share of total revenue.

| Segment | Revenue Share |
|---|---|
| Top 20% | **53.5%** |
| 21–40% | 20.0% |
| 41–60% | 13.1% |
| 61–80% | 8.5% |
| Bottom 20% | 4.8% |

**Finding:** The top 20% drove over half of all revenue. Retaining high-value customers is the #1 priority.

---

## Tableau Dashboard

A 5-view interactive Tableau dashboard was built to visualize the SQL results, including:

- Monthly revenue trend (2017–2018)
- Monthly order volume
- Top 10 product categories by revenue
- Customer segmentation by revenue quintile
- Fastest growing categories
- CLV distribution by spend bucket

---

## File Structure

```
ecommerce-analytics/
├── queries.sql     # All SQL queries with comments
└── README.md       # This file
```

---

## SQL Concepts Used

- **CTEs** for readable multi-step queries
- **Window Functions** — `LAG()`, `NTILE()`, `RANK()`, `DENSE_RANK()`
- **Aggregations** — `SUM`, `COUNT`, `AVG`, `MIN`, `MAX`
- **JOINs** — multi-table joins across 4–5 tables
- **Date functions** — `STRFTIME` for month-level grouping
- **Cohort Analysis** — grouping customers by first purchase month
- **Conditional aggregation** — `CASE WHEN` inside `SUM`

---

## Key Takeaways

1. **Retention is the biggest lever** — 3% repeat rate means most revenue comes from new acquisition. Moving this to 10% would materially increase LTV.
2. **The Pareto rule holds** — top 20% of customers = 53.5% of revenue. Segment and target them differently.
3. **Seasonality matters** — November spike suggests Black Friday drives outsized demand.
4. **Emerging categories** — construction tools and fashion accessories are growing fast from a small base.

---

*Dataset used for learning and portfolio purposes only.*
