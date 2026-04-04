--testings--
--customers table
SELECT* 
FROM bronze.customers
--1.customerkey

--check for duplicates
SELECT customerkey, 
	   COUNT(*)
FROM bronze.customers
GROUP BY 1
HAVING COUNT(*) >1


SELECT DISTINCT gender
FROM bronze.customers

--check for unwanted spaces
SELECT gender
FROM bronze.customers
WHERE gender <> TRIM(gender);

--check for unwanted spaces
SELECT name
FROM bronze.customers
WHERE name <> TRIM(name);

--check for null valus
SELECT name
FROM bronze.customers
WHERE  name IS NULL

--check for unwanted spaces
SELECT city
FROM bronze.customers
WHERE city <> TRIM(city);

--check for null valus
SELECT city
FROM bronze.customers
WHERE  city IS NULL


--check for unwanted spaces
SELECT state_code
FROM bronze.customers
WHERE state_code <> TRIM(state_code);

--check for null valus
SELECT state_code
FROM bronze.customers
WHERE  state_code IS NULL;

--check for unwanted spaces
SELECT state
FROM bronze.customers
WHERE state <> TRIM(state);

--check for null valus
SELECT state
FROM bronze.customers
WHERE  state IS NULL;



SELECT zip_code
FROM bronze.customers
WHERE  zip_code IS NULL;

SELECT country
FROM bronze.customers
WHERE country <> TRIM(country);


SELECT country
FROM bronze.customers
WHERE  country IS NULL;

--chech for unwanted spaces
SELECT continent
FROM bronze.customers
WHERE continent <> TRIM(continent);

--check for null valus
SELECT continent
FROM bronze.customers
WHERE  continent IS NULL;

-- check for null values
SELECT birthday
FROM bronze.customers
WHERE birthday IS NULL
   OR TRIM(birthday::text) = '';
--Check for unrealistic values
SELECT birthday
FROM bronze.customers
WHERE birthday < CURRENT_DATE - INTERVAL '90 years';

-- age distribution
SELECT 
    DATE_PART('year', AGE(birthday)) AS age,
    COUNT(*) 
FROM bronze.customers
GROUP BY age
ORDER BY age;

--now  create the main query and load into silver table




--ex_rates table
SELECT * FROM bronze.ex_rates


--check for duplicates
SELECT date, currency, COUNT(*)
FROM bronze.ex_rates
GROUP BY date, currency
HAVING COUNT(*) > 1;


--check for unwanted spaces
SELECT currency
FROM bronze.ex_rates
WHERE currency <> TRIM(currency);

--check for rate <0
SELECT *
FROM bronze.ex_rates
WHERE exchange <0

--3.products
SELECT * FROM bronze.products

--check for duplicates
SELECT productkey,
		COUNT(*)
FROM bronze.products
GROUP BY 1
HAVING COUNT(*) >1

--check for null values
SELECT productkey
FROM bronze.products
WHERE productkey IS NULL


--unique values
SELECT DISTINCT brand
FROM bronze.products

SELECT DISTINCT color
FROM bronze.products

SELECT DISTINCT subcategory
FROM bronze.products

SELECT DISTINCT category
FROM bronze.products
--lets update the query




--4.sales table--

SELECT * FROM bronze.sales

SELECT customerkey
FROM bronze.sales
WHERE customerkey NOT  IN (
    SELECT customerkey
    FROM bronze.customers
);


SELECT customerkey
FROM bronze.sales
WHERE customerkey IS NULL


SELECT order_date
FROM bronze.sales
WHERE order_date IS NUll



SELECT productkey
FROM bronze.sales
WHERE productkey NOT  IN (
    SELECT productkey
    FROM bronze.products
);

SELECT quantity 
FROM bronze.sales
WHERE quantity <1


SELECT DISTINCT currency_code
FROM bronze.sales

SELECT delivery_date
FROM bronze.sales
WHERE delivery_date IS NULL

SELECT *
FROM bronze.sales
WHERE order_date > delivery_date

SELECT storekey
FROM bronze.sales
WHERE storekey NOT  IN (
    SELECT storekey
    FROM bronze.stores
);
--create a main query


--5. stores table
SELECT s.order_date
FROM bronze.sales s
JOIN bronze.stores st
    ON s.storekey = st.storekey
WHERE s.order_date < st.open_date;

SELECT  DISTINCT storekey
FROM bronze.stores
ORDER BY 1

SELECT * FROM bronze.stores
WHERE open_date IS NULL


SELECT * FROM silver.customers
SELECT * FROM silver.products
SELECT * FROM silver.ex_rates
SELECT * FROM silver.sales
SELECT * FROM silver.stores


