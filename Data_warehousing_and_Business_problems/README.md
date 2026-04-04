
# 📊 Retail Data Analytics Project (PostgreSQL)

## 🏗️ Medallion Data Architecture



<img width="1820" height="900" alt="Data warehousing architecture infographic" src="https://github.com/user-attachments/assets/abc46c88-3ded-412b-acd6-a24fa7842a18" />




This project is designed using the **Medallion Architecture (Bronze → Silver → Gold)** to ensure scalable, clean, and analytics-ready data.

### 🥉 Bronze Layer
- Raw ingestion from source systems
- No transformations

### 🥈 Silver Layer
- Data cleaning & standardization
- Handling missing values, duplicates, formatting

### 🥇 Gold Layer (Analytics Layer)
- Star schema design:
  - fact_sales
  - dim_customers
  - dim_products
  - dim_stores

👉 All business problems are solved using the **Gold Layer**, ensuring consistency and performance.

---

# 📈 Key Business Problems & Advanced SQL Solutions

---

## 1. Customer Value Segmentation

```sql
CREATE TABLE customer_segment AS 
WITH cust_rev AS (
SELECT c.customer_key,
       c.name,
       c.age,
       SUM(s.amount_usd) AS total_sales
FROM gold.dim_customers c
JOIN gold.fact_sales s
ON c.customer_key = s.customer_key
GROUP BY 1,2,3
)
SELECT *,
CASE 
    WHEN total_sales >30000 THEN 'High Value'
    WHEN total_sales BETWEEN 20000 AND 30000 THEN 'Middle Value'
    ELSE 'Low Value'
END AS cust_segment
FROM cust_rev;
```

### 💡 Insight
Revenue is highly concentrated among a very small percentage of customers.

### 🚀 Action
Prioritize high-value customers and implement upselling strategies.

---

## 2. Revenue Growth Monitoring (Window Functions)

```sql
WITH sales AS (
SELECT EXTRACT(YEAR FROM order_date) AS year,
       EXTRACT(MONTH FROM order_date) AS month,
       SUM(amount_usd) AS total_sales
FROM gold.fact_sales
GROUP BY 1,2
)
SELECT year, month, total_sales,
COALESCE(LAG(total_sales) OVER (ORDER BY year, month),0) AS prev_month_sales,
total_sales - COALESCE(LAG(total_sales) OVER (ORDER BY year, month),0) AS growth_amount,
CASE 
WHEN COALESCE(LAG(total_sales) OVER (ORDER BY year, month),0)=0 THEN '0%'
ELSE ROUND(
(total_sales - LAG(total_sales) OVER (ORDER BY year, month))
/ LAG(total_sales) OVER (ORDER BY year, month) * 100,2)::TEXT || '%'
END AS growth_percent
FROM sales;
```

### 💡 Insight
Revenue shows volatility → indicates seasonality or inconsistent demand.

### 🚀 Action
Forecast demand and stabilize revenue streams.

---

## 3. Product Performance Ranking

```sql
WITH cte AS (
SELECT EXTRACT(YEAR FROM order_date) AS year,
       p.product_name,
       p.category,
       SUM(amount_usd) AS total_sales
FROM gold.dim_products p
JOIN gold.fact_sales s
ON p.product_key = s.product_key
GROUP BY 1,2,3
),
ranked AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY year, category ORDER BY total_sales DESC) AS rank
FROM cte
)
SELECT * FROM ranked WHERE rank = 1;
```

### 💡 Insight
Few products dominate each category.

### 🚀 Action
Focus inventory & marketing on top-performing SKUs.

---

## 4. Customer Retention & Loyalty Segmentation

```sql
CREATE TABLE customer_loyalty AS 
WITH customer_orders AS (
SELECT c.customer_key,
       c.name,
       COUNT(DISTINCT s.order_number) AS total_orders
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales s
ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.name
)
SELECT *,
CASE 
WHEN total_orders >= 10 THEN 'Loyal'
WHEN total_orders BETWEEN 2 AND 9 THEN 'Repeat'
WHEN total_orders = 1 THEN 'One-Time'
ELSE 'No Purchase'
END AS customer_segment
FROM customer_orders;
```

### 💡 Insight
Extremely low loyal customers → weak retention.

### 🚀 Action
Introduce loyalty programs & retention campaigns.

---

## 5. Regional Sales Analysis

```sql
WITH customer_spending AS (
SELECT c.customer_key,
       c.country,
       c.state,
       EXTRACT(YEAR FROM s.order_date) AS year,
       SUM(s.amount_usd) AS total_spent
FROM gold.fact_sales s
JOIN gold.dim_customers c
ON s.customer_key = c.customer_key
GROUP BY 1,2,3,4
),
country_avg AS (
SELECT year, country, state,
ROUND(AVG(total_spent),3) AS avg_customer_spending
FROM customer_spending
GROUP BY 1,2,3
),
ranked AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY year, country ORDER BY avg_customer_spending DESC) AS rank
FROM country_avg
)
SELECT * FROM ranked WHERE rank = 1;
```

### 💡 Insight
Customer spending varies significantly across regions.

### 🚀 Action
Adopt region-specific pricing & marketing.

---

## 6. Store Performance Benchmarking

```sql
WITH store_metrics AS (
SELECT EXTRACT(YEAR FROM s.order_date) AS year,
       st.store_key,
       st.country,
       st.state,
       SUM(s.amount_usd) AS total_sales,
       COUNT(DISTINCT s.order_number) AS total_orders
FROM gold.fact_sales s
JOIN gold.dim_stores st
ON s.store_key = st.store_key
WHERE st.country != 'Online'
GROUP BY 1,2,3,4
),
ranked AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY country, year ORDER BY total_sales DESC) AS revenue_rank,
DENSE_RANK() OVER(PARTITION BY country, year ORDER BY total_orders DESC) AS order_rank
FROM store_metrics
)
SELECT * FROM ranked
WHERE revenue_rank = 1 AND order_rank = 1;
```

### 💡 Insight
Top performance concentrated in few regions.

### 🚀 Action
Replicate high-performing store strategies.

---

## 7. Profitability Analysis

```sql
WITH cte AS (
SELECT EXTRACT(YEAR FROM s.order_date) AS year,
       p.product_name,
       SUM(s.amount_usd - (s.quantity * p.unit_cost)) AS profit
FROM gold.fact_sales s
JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY 1,2
),
ranked AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY year ORDER BY profit DESC) AS rank
FROM cte
)
SELECT * FROM ranked WHERE rank = 1;
```

### 💡 Insight
Profit driven by few high-margin products.

### 🚀 Action
Focus on high-margin product strategy.

---

## 8. Category Contribution (Window Functions)

```sql
WITH cte AS (
SELECT EXTRACT(YEAR FROM s.order_date) AS year,
       p.category,
       SUM(s.amount_usd - (s.quantity * p.unit_cost)) AS profit
FROM gold.fact_sales s
JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY 1,2
)
SELECT *,
ROUND(profit / SUM(profit) OVER(PARTITION BY year) * 100,2)::TEXT || '%' AS contribution
FROM cte;
```

### 💡 Insight
Category contribution shifts over time.

### 🚀 Action
Invest in high-performing categories.

---

## 9. Customer Churn Analysis (Advanced)

```sql
CREATE TABLE customer_churn AS
WITH cte AS (
SELECT s.customer_key,
       MAX(s.order_date) AS last_order_date
FROM gold.fact_sales s
GROUP BY 1
)
SELECT *,
CURRENT_DATE - last_order_date AS days_since_last_order,
CASE 
WHEN CURRENT_DATE - last_order_date > 365 THEN 'Churned'
WHEN CURRENT_DATE - last_order_date BETWEEN 240 AND 365 THEN 'At Risk'
ELSE 'Active'
END AS status
FROM cte;
```

### 💡 Insight
Very high churn rate (~80%).

### 🚀 Action
Implement retention & reactivation campaigns.

---

## 10. Store Space Efficiency (Percentiles)

```sql
WITH store_perf AS (
SELECT s.store_key,
       st.country,
       st.square_meters,
       SUM(s.amount_usd) AS total_sales,
       SUM(s.amount_usd)/NULLIF(st.square_meters,0) AS revenue_per_sqm
FROM gold.fact_sales s
JOIN gold.dim_stores st
ON s.store_key = st.store_key
GROUP BY 1,2,3
),
percentiles AS (
SELECT 
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue_per_sqm) AS p25,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue_per_sqm) AS p75
FROM store_perf
)
SELECT sp.*,
CASE 
WHEN revenue_per_sqm >= p75 THEN 'Top Performer'
WHEN revenue_per_sqm <= p25 THEN 'Underperforming'
ELSE 'Average'
END AS performance_category
FROM store_perf sp
CROSS JOIN percentiles;
```

### 💡 Insight
Multiple stores underperform relative to size.

### 🚀 Action
Optimize or restructure low-performing stores.

---

# 🏆 Project Highlights

- Advanced SQL: CTEs, Window Functions, Ranking, Percentiles
- Data Warehousing: Medallion Architecture
- Business Thinking: Insights + Actions
- Real-world Analytics Use Cases

---

# 🚀 Outcome

This project demonstrates the ability to:
- Transform raw data into business insights
- Solve real-world business problems using SQL
- Apply data warehousing best practices

