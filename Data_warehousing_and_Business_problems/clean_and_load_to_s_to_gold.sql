CREATE VIEW gold.fact_sales AS

SELECT 
       s.order_number,
       s.line_item,
       s.order_date,
       s.delivery_states,
       s.delivery_date,
       c.customer_key,
       st.store_key,
       p.product_key,
       s.quantity,
       s.currency_code,
       CASE 
           WHEN s.currency_code = 'USD' 
                THEN ROUND(CAST(p.unit_price AS NUMERIC) * s.quantity,3)
           WHEN ex.exchange IS NOT NULL 
                THEN ROUND(ex.exchange::numeric * CAST(p.unit_price AS NUMERIC) * s.quantity::numeric,3)
           ELSE NULL
       END AS amount_usd
FROM silver.sales s
LEFT JOIN gold.dim_products p
    ON s.productkey = p.product_id
LEFT JOIN gold.dim_customers c
    ON s.customerkey = c.customer_id
LEFT JOIN gold.dim_stores st
    ON s.storekey = st.store_id
LEFT JOIN silver.ex_rates ex
    ON s.currency_code = ex.currency
   AND s.order_date = ex.date;



