-- Clean and load customer table into silver table ---
INSERT INTO silver.customers(
customerkey,
gender,
name,
city,
state_code,
state,
zip_code,
country,
continent,
birthday
)
SELECT  customerkey,
        TRIM(gender) AS gender,
        TRIM(name) AS name, 
        TRIM(city) AS city, 
        state_code, 
        TRIM(state) AS state, 
        zip_code,
        TRIM(country) AS country,    
        TRIM(continent) AS continent, 
        birthday
FROM bronze.customers
WHERE birthday >= CURRENT_DATE - INTERVAL '90 years';


-- Clean and load ex_rates table into silver table ---
INSERT INTO silver.ex_rates (
    date,
    currency,
    exchange
)
SELECT  
    date,
    TRIM(currency) AS currency,
	exchange

FROM bronze.ex_rates
WHERE date IS NOT NULL
  AND currency IS NOT NULL
  AND exchange >0 AND exchange IS NOT NULL;

--clean and load data into silver.products
INSERT INTO silver.products (
    productkey,
    product_name,
    brand,
    color,
    unit_cost_usd,
    unit_price_usd,
    subcategory_key,
    subcategory,
    category_key,
    category
)
SELECT  
    productkey,
    TRIM(product_name) AS product_name,
    TRIM(brand) AS brand,
    TRIM(color) AS color,
    REPLACE(REPLACE(TRIM(unit_cost_usd), '$', ''), ',', '')::NUMERIC AS unit_cost_usd,
    REPLACE(REPLACE(TRIM(unit_price_usd), '$', ''), ',', '')::NUMERIC AS unit_price_usd,
    subcategory_key,
    TRIM(subcategory) AS subcategory,
    category_key,
    TRIM(category) AS category

FROM bronze.products;



--clean and load into silver.sales--
INSERT INTO silver.sales(
    order_number,
    line_item,
    order_date,
    delivery_states,
    delivery_date,
    customerkey,
    storekey,
    productkey,
    quantity,
    currency_code
)
SELECT  s.order_number,
        s.line_item,
        s.order_date,
        CASE 
            WHEN s.delivery_date IS NULL THEN 'processing'
            ELSE 'delivered'
        END AS delivery_states,
        s.delivery_date,
        s.customerkey,        
        s.storekey,
        s.productkey,
        s.quantity,
        TRIM(s.currency_code)

FROM bronze.sales s
JOIN bronze.stores st
    ON s.storekey = st.storekey

WHERE s.order_number IS NOT NULL 
  AND s.order_date IS NOT NULL 
  
  AND s.order_date >= st.open_date  

  AND s.customerkey IN (
        SELECT customerkey
        FROM bronze.customers
  )

  AND s.productkey IN (
        SELECT productkey
        FROM bronze.products
  ) 

  AND s.quantity > 0;

--clean and load into silver.stores
INSERT INTO silver.stores(
storekey,
country,
state,
square_meters,
open_date
)
SELECT  storekey,
        TRIM(country),
        TRIM(state),
        CASE 
            WHEN storekey = 0 THEN 0
            ELSE square_meters
        END AS square_meters,      
        open_date

FROM bronze.stores
WHERE open_date IS NOT NULL;
