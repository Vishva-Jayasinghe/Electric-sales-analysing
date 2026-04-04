[FINAL_Retail_README.md](https://github.com/user-attachments/files/26480584/FINAL_Retail_README.md)

# 📊 Retail Data Analytics Project (Medallion Architecture)

<img width="1536" height="1024" alt="Data warehousing architecture infographic" src="https://github.com/user-attachments/assets/42291a43-d80c-4919-8827-5889df5c00a3" />





## 🏗️ Medallion Architecture

This project follows the Medallion Architecture:

### Bronze
Raw data ingestion

### Silver
Cleaned and transformed data

### Gold
Business-ready star schema:
- fact_sales
- dim_customers
- dim_products
- dim_stores

All analysis is performed on the Gold layer.

---

# 📈 Business Problems & SQL Solutions

## 1. Customer Value Segmentation
```sql
WITH cust_rev AS (
SELECT c.customer_key, c.name, c.age,
       SUM(s.amount_usd) AS total_sales
FROM gold.dim_customers c
JOIN gold.fact_sales s
ON c.customer_key = s.customer_key
GROUP BY 1,2,3
)
SELECT *,
CASE WHEN total_sales >30000 THEN 'High Value'
     WHEN total_sales BETWEEN 20000 AND 30000 THEN 'Middle Value'
     ELSE 'Low Value'
END AS cust_segment
FROM cust_rev;
```
**Insight:** Revenue concentrated in few customers  
**Action:** Focus on retention & upselling

---

## 2. Revenue Growth Monitoring
```sql
WITH sales AS (
SELECT EXTRACT(YEAR FROM order_date) AS year,
       EXTRACT(MONTH FROM order_date) AS month,
       SUM(amount_usd) AS total_sales
FROM gold.fact_sales
GROUP BY 1,2
)
SELECT *,
COALESCE(LAG(total_sales) OVER (ORDER BY year, month),0) AS prev_month,
total_sales - COALESCE(LAG(total_sales) OVER (ORDER BY year, month),0) AS growth
FROM sales;
```
**Insight:** Fluctuating growth  
**Action:** Identify trends & seasonality

---

## 3. Product Performance
```sql
WITH cte AS (
SELECT p.product_name, p.category,
SUM(amount_usd) AS total_sales
FROM gold.dim_products p
JOIN gold.fact_sales s
ON p.product_key = s.product_key
GROUP BY 1,2
),
ranked AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY category ORDER BY total_sales DESC) AS rank
FROM cte
)
SELECT * FROM ranked WHERE rank=1;
```
**Insight:** Few products dominate  
**Action:** Optimize inventory

---

## 4. Customer Retention
```sql
SELECT customer_key,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales
GROUP BY 1;
```
**Insight:** Low loyalty  
**Action:** Loyalty programs

---

## 5. Regional Sales
```sql
SELECT country,
AVG(amount_usd) AS avg_sales
FROM gold.fact_sales s
JOIN gold.dim_customers c
ON s.customer_key=c.customer_key
GROUP BY country;
```
**Insight:** Regional variation  
**Action:** Local strategies

---

## 6. Store Performance
```sql
SELECT store_key,
SUM(amount_usd) AS total_sales
FROM gold.fact_sales
GROUP BY store_key;
```
**Insight:** Performance differs by region  
**Action:** Replicate best stores

---

## 7. Profitability
```sql
SELECT p.product_name,
SUM(s.amount_usd - s.quantity*p.unit_cost) AS profit
FROM gold.fact_sales s
JOIN gold.dim_products p
ON s.product_key=p.product_key
GROUP BY 1;
```
**Insight:** Profit driven by few products  
**Action:** Focus on margins

---

## 8. Category Contribution
```sql
SELECT p.category,
SUM(s.amount_usd) AS revenue
FROM gold.fact_sales s
JOIN gold.dim_products p
ON s.product_key=p.product_key
GROUP BY 1;
```
**Insight:** Category dominance shifts  
**Action:** Invest strategically

---

## 9. Customer Churn
```sql
SELECT customer_key,
MAX(order_date) AS last_order
FROM gold.fact_sales
GROUP BY 1;
```
**Insight:** High churn  
**Action:** Re-engagement campaigns

---

## 10. Store Efficiency
```sql
SELECT st.store_key,
SUM(s.amount_usd)/st.square_meters AS revenue_per_sqm
FROM gold.fact_sales s
JOIN gold.dim_stores st
ON s.store_key=st.store_key
GROUP BY st.store_key, st.square_meters;
```
**Insight:** Underperforming stores exist  
**Action:** Optimize or close stores

---

# 🚀 Conclusion
- Advanced SQL (CTE, Window Functions)
- Data Warehousing (Medallion)
- Business Insights

