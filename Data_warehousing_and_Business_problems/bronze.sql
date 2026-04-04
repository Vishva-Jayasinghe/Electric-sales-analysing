--bronze schema creating
CREATE TABLE bronze.customers(
customerkey INT,
gender VARCHAR(10),
name VARCHAR(50),
city VARCHAR(75),
state_code VARCHAR(10),
state VARCHAR(25),
zip_code INT,
country	VARCHAR(75),
continent VARCHAR(75),
birthday DATE

);


CREATE TABLE bronze.ex_rates(
date DATE ,
currency VARCHAR(10),
Exchange FLOAT

);

CREATE TABLE bronze.products(
productkey INT,
product_name VARCHAR(200),
brand VARCHAR(100),
color VARCHAR(30),
unit_cost_USD TEXT,
unit_price_USD TEXT,
subcategory_key INT,
subcategory	VARCHAR(150),
category_key INT,
category VARCHAR(150)
);


CREATE TABLE bronze.sales(
order_number INT,
line_item INT ,
order_date DATE,
delivery_date DATE,
customerkey INT,
storekey INT,
Productkey INT,
quantity INT,
currency_code VARCHAR(30)
);

CREATE TABLE bronze.stores(
storekey INT,
country VARCHAR(75),
state VARCHAR(75),
square_meters FLOAT,
open_date DATE

);


SELECT * FROM bronze.customers
SELECT * FROM bronze.ex_rates
SELECT * FROM bronze.products
SELECT * FROM bronze.sales
SELECT * FROM bronze.stores