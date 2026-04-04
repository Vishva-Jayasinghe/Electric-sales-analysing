
[Retail_Data_Analytics_README.md](https://github.com/user-attachments/files/26480577/Retail_Data_Analytics_README.md)

# 📊 Retail Data Analytics Project (Medallion Architecture)


<img width="1536" height="1024" alt="Data warehousing architecture infographic" src="https://github.com/user-attachments/assets/03103411-1592-4609-b74b-2c65718c8e2b" />


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 🏗️ Data Architecture: Medallion Approach

This project follows the Medallion Architecture to ensure scalable, clean, and business-ready data processing.

### 🥉 Bronze Layer (Raw Data)
- Raw ingested data from source systems
- No transformations applied

### 🥈 Silver Layer (Cleaned Data)
- Data cleaning and standardization
- Handled missing values, duplicates, data types

### 🥇 Gold Layer (Analytics Layer)
- Star schema design:
  - fact_sales
  - dim_customers
  - dim_products
  - dim_stores
- All business queries are built on this layer

---

# 📈 Business Problems & Insights

## 1. Customer Value Segmentation

### SQL
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

### Insight
Most customers fall into the low-value segment, indicating revenue concentration among a small group.

### Recommendation
Focus on retaining high-value customers and converting mid-value customers through targeted marketing.

---

## 2. Revenue Growth Monitoring

### Insight
Revenue fluctuates month-to-month, indicating unstable growth patterns.

### Recommendation
Identify high-performing periods and replicate successful strategies while addressing decline periods.

---

## 3. Product Performance

### Insight
Few products dominate category performance.

### Recommendation
Optimize inventory and promote high-performing products.

---

## 4. Customer Retention

### Insight
Very low loyal customer percentage.

### Recommendation
Introduce loyalty programs and retention campaigns.

---

## 5. Regional Sales

### Insight
Customer spending varies significantly by region.

### Recommendation
Adopt region-specific strategies.

---

## 6. Store Performance

### Insight
USA and Australia dominate store performance.

### Recommendation
Replicate successful strategies across regions.

---

## 7. Profitability Analysis

### Insight
Profit driven by few products.

### Recommendation
Focus on high-margin products.

---

## 8. Category Contribution

### Insight
Shift in demand toward computers category.

### Recommendation
Invest in trending categories.

---

## 9. Customer Churn

### Insight
High churn rate (~80%).

### Recommendation
Implement re-engagement strategies.

---

## 10. Store Space Efficiency

### Insight
Several stores underperform relative to size.

### Recommendation
Optimize or restructure underperforming stores.

---

# 🚀 Conclusion

This project demonstrates:
- Advanced SQL (CTEs, Window Functions)
- Data Warehousing (Medallion Architecture)
- Business Insight Generation

