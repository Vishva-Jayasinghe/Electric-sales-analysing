                                 ---------- Business problems ----------


/* 1. Customer Value Segmentation
The company wants to identify its most valuable customers to prioritize marketing efforts.
Problem:
Which customers contribute the highest revenue, and how can we segment customers into 
high, medium, and low value groups?
*/

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
ORDER BY 4 DESC
)
SELECT *,
	   CASE WHEN total_sales >30000 THEN 'High Value'
	   	    WHEN total_sales BETWEEN 20000 AND 30000 THEN'Middle Value'
			ELSE  'Low Value'
		END AS cust_segment
FROM cust_rev

--perentage of customer_segments
SELECT 
    cust_segment,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) || '%' AS per
FROM customer_segment
GROUP BY cust_segment;
/*Insights :  almost 97% customers are low valued( total revenue <20000)
only 42% are high valued (total revenue >30000)
others are middle valued
*/


/* 2. Revenue Growth Monitoring

Management wants to track business performance over time.
Problem:

How has monthly revenue changed over time, and what are the growth trends from month to month?
*/
WITH sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(MONTH FROM order_date) AS month,
        SUM(amount_usd) AS total_sales
    FROM gold.fact_sales
    GROUP BY 1,2
)

SELECT 
    year,
    month,
    total_sales,

    COALESCE(
        LAG(total_sales) OVER (ORDER BY year, month), 
        0
    ) AS prev_month_sales,

    total_sales - COALESCE(
        LAG(total_sales) OVER (ORDER BY year, month), 
        0
    ) AS growth_amount,

    CASE 
        WHEN COALESCE(LAG(total_sales) OVER (ORDER BY year, month), 0) = 0 
            THEN '0%'
        ELSE 
            ROUND(
                (total_sales - LAG(total_sales) OVER (ORDER BY year, month)) 
                / LAG(total_sales) OVER (ORDER BY year, month) * 100, 
            2)::TEXT || '%'
    END AS growth_percent

FROM sales
ORDER BY year, month;


/* 3. Product Performance Within Categories
The product team wants to optimize inventory and promotions.
Problem:
Which products are the top performers within each category,
and how do they compare to others in the same category?
*/
WITH cte AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        p.product_name,
        p.category,
        SUM(amount_usd) AS total_sales
    FROM gold.dim_products p
    JOIN gold.fact_sales s
        ON p.product_key = s.product_key
    GROUP BY 1,2,3
	ORDER BY 1,2,3
),

ranked AS (
    SELECT *,
           DENSE_RANK() OVER(
               PARTITION BY year, category 
               ORDER BY total_sales DESC
           ) AS rank
    FROM cte
)

SELECT *
FROM ranked
WHERE rank <=1; 



/* 4. Customer Retention Strategy

The marketing team wants to improve customer loyalty.

Problem: how can we identify loyal ,repeat vs  one-time customers? 

*/
CREATE TABLE customer_loyalty AS 
WITH customer_orders AS (
    SELECT 
        c.customer_key,
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
FROM customer_orders
ORDER BY total_orders DESC;

--perentage of customer_loyalty
SELECT 
    customer_segment AS segment,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) || '%' AS percentage
FROM customer_loyalty
GROUP BY 1;

--Insights : almost 29% are one time ,49.11% are repeat , almost 22% are no purchase and ony 0.12% are loyal




/*
5. Regional Sales Behavior
The company operates globally and wants to understand regional differences.
Problem:
How does average customer spending vary across different countries?
*/


WITH customer_spending AS (
SELECT 
        c.customer_key,
        c.country,
        c.state,
        EXTRACT(YEAR FROM s.order_date) AS year,
        SUM(s.amount_usd) AS total_spent
    FROM gold.fact_sales s
    JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key, c.country, c.state, year
),
country_avg AS (
    SELECT 
        year,
        country,
        state,
        ROUND(AVG(total_spent), 3) AS avg_customer_spending
    FROM customer_spending
    GROUP BY year, country, state
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER(
               PARTITION BY year, country 
               ORDER BY avg_customer_spending DESC
           ) AS rank
    FROM country_avg
)
SELECT *
FROM ranked
WHERE rank <= 1; 


/*
6. Store Performance Benchmarking
The retail team wants to evaluate store efficiency.
Problem:
Which stores generate the highest revenue and order volume in each year, 
and how do they rank compared to others?
*/

CREATE TABLE stores_performance AS 
WITH store_metrics AS (
    SELECT 
	    EXTRACT(YEAR FROM s.order_date) AS year,
        st.store_key AS store_key,
        st.country AS country,
        st.state AS state,
        SUM(s.amount_usd) AS total_sales,
        COUNT(DISTINCT s.order_number) AS total_orders
    FROM gold.fact_sales s
    JOIN gold.dim_stores st
        ON s.store_key = st.store_key
    WHERE st.country != 'Online' 
      AND st.state != 'Online'
    GROUP BY st.store_key, st.country, st.state, year
),

ranked AS (
    SELECT *,
           DENSE_RANK() OVER(PARTITION BY country, year ORDER BY total_sales DESC) AS revenue_rank,           
           DENSE_RANK() OVER(PARTITION BY country, year ORDER BY total_orders DESC) AS order_rank
    FROM store_metrics
)
SELECT year,
	   store_key,
	   country,
	   total_sales,
	   total_orders,
	   DENSE_RANK() OVER(PARTITION BY year ORDER BY total_sales DESC) AS rank
FROM ranked
WHERE revenue_rank = 1 
    AND order_rank = 1
ORDER BY year, country


-- If we want to see the best store in each year by total_sales
SELECT * FROM stores_performance
WHERE rank =1;

/*
Insights :
2016 : Australia
2017 : US
2018 : Australia
2019 : Australia
2020 :  US
2021 : US
*/





/* 7. Profitability Analysis

Finance wants to identify profitable products.

Problem:
Which products generate the highest profit in each year
*/
WITH cte1 AS (
SELECT 
	   EXTRACT(YEAR FROM s.order_date)AS year,
	   s.product_key,
	   p.product_name,
	   SUM(s.amount_usd) AS total_sales,
	   SUM(s.quantity * p.unit_cost) AS total_cost,
	   SUM(s.amount_usd - (s.quantity *p.unit_cost)) AS profit
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY 1,2,3
ORDER BY 1
), ranked_data AS (
SELECT *,
	  DENSE_RANK() OVER(PARTITION BY year ORDER BY profit DESC) AS rank
FROM cte1
)
SELECT year,
	   product_key,
	   product_name,
	   profit
FROM ranked_data
WHERE rank =1


/*
8. Category Contribution to Revenue
Leadership wants to focus on key revenue drivers.
Problem:
Which product categories contribute the most to profit,
and what percentage of revenue does each category represent?
*/
WITH cte1 AS (
SELECT EXTRACT(YEAR FROM s.order_date) AS year,
	   p.category,
	   SUM(s.amount_usd) AS total_sales,
	   SUM(s.quantity * p.unit_cost) AS total_cost,
	   SUM(s.amount_usd - (s.quantity *p.unit_cost)) AS profit
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY 1,2
ORDER BY 1,2
), cte2  AS (
SELECT year,
	   category,
	   profit
FROM cte1
) , cte3 AS (
SELECT *,
	     ROUND(profit/SUM(profit) OVER(PARTITION  BY year)::numeric,3) * 100 || '%' AS percentage
FROM cte2
),ranked AS (
SELECT *,
	   DENSE_RANK() OVER(PARTITION BY year ORDER BY profit DESC) AS rank

FROM cte3
)
SELECT year,
	   category,
	   profit,
	   percentage
FROM ranked 
WHERE rank =1;

/*
Insights :
highest after 2016 the most contributed cactegory for profit is computers and in 2016 its Home applications
*/





/*
9. Customer Churn Identification

The company wants to reduce lost customers.
Problem:
Which customers have stopped purchasing, and how can we identify those at risk of churn?

*/

CREATE TABLE customer_churn AS
WITH cte1 AS (
    SELECT 
        s.customer_key,
        c.name,
        COUNT(DISTINCT s.order_number) AS total_orders,
        MAX(s.order_date) AS last_order_date
    FROM gold.fact_sales s
    JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    WHERE s.delivery_states ='delivered'
    GROUP BY 1,2
	
)

SELECT 
    *,
    MAX(last_order_date) OVER () - last_order_date AS days_since_last_order,
    CASE 
        WHEN MAX(last_order_date) OVER () - last_order_date > 365 THEN 'Churned'
        WHEN MAX(last_order_date) OVER () - last_order_date BETWEEN 240 AND 365 THEN 'At Risk'
        ELSE 'Active'
    END AS customer_status
FROM cte1
ORDER BY MAX(last_order_date) OVER () - last_order_date DESC;

--- if someone wants to get churned, At-Risk and Active percentages
WITH cte1 AS (
    SELECT  
        customer_status,
        COUNT(*) AS count
    FROM customer_churn
    GROUP BY customer_status
)
SELECT 
    customer_status,
    count,
    ROUND(count * 100.0 / SUM(count) OVER (),3) || '%' AS percentage
FROM cte1;
-- Insights : Almost 80% customers  are churned

/*
10. Store Space Efficiency
Real estate and operations teams want better utilization of space.
Problem:
Which stores generate the most revenue relative to their physical size, 
and which stores are underperforming?
*/
CREATE TABLE store_performance AS 
WITH store_performance AS (
    SELECT 
        s.store_key,
        st.country,
        st.state,
        st.square_meters,
        SUM(s.amount_usd) AS total_sales,
        SUM(s.amount_usd) / NULLIF(st.square_meters, 0) AS revenue_per_sqm
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_stores st
        ON s.store_key = st.store_key
    WHERE s.store_key != 1 -- we cant compare online store
    GROUP BY 1,2,3,4
),
percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue_per_sqm) AS p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue_per_sqm) AS p75
    FROM store_performance
), cte3 AS (
SELECT *,
       CASE 
           WHEN revenue_per_sqm >= p75 THEN 'Top Performer'
           WHEN revenue_per_sqm <= p25 THEN 'Underperforming'
           ELSE 'Average'
       END AS performance_category
FROM store_performance
CROSS JOIN percentiles
)
SELECT store_key,
	   country,
	   square_meters,
	   performance_category
FROM cte3


--underperforming stores
SELECT * FROM store_performance
WHERE performance_category = 'Underperforming' 

-- Insights : 11 stores are underperforming and most of them are in Germany
