-- Step 1: Preview the raw data and inspect the table structure
SELECT *
FROM `bigquery-public-data.iowa_liquor_sales.sales`
LIMIT 100;

-- Step 2: Extract transaction-level records for the four target brands
SELECT
CASE
WHEN REGEXP_CONTAINS(UPPER(item_description), r'MR\s*BLACK')
THEN
'MR BLACK'
WHEN REGEXP_CONTAINS(UPPER(item_description), r'STARWARD')
THEN
'STARWARD'
WHEN REGEXP_CONTAINS(UPPER(item_description), r'DON\s*PAPA')
THEN
'DON PAPA'
WHEN REGEXP_CONTAINS(UPPER(item_description), r'MEZCAL\s*UNION|UNION\s*MEZCAL')
THEN
'MEZCAL UNION'
END AS BRAND,

date,
vendor_number,
vendor_name,
store_number,
store_name,
city,
county,
item_number,
item_description,
pack,
bottle_volume_ml,
bottles_sold,
sale_dollars

FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE
REGEXP_CONTAINS(UPPER(item_description), r'STARWARD|DON\s*PAPA|MR\s*BLACK|MEZCAL\s*UNION|UNION\s*MEZCAL')
ORDER BY BRAND, DATE;

-- Step 3: Summarise transaction history by brand and vendor
WITH brand_patterns AS (
SELECT *
FROM UNNEST([
STRUCT('MR BLACK' AS brand, r'MR\s*BLACK' AS pattern),
STRUCT('STARWARD' AS brand, r'STARWARD' AS pattern),
STRUCT('DON PAPA' AS brand, r'DON\s*PAPA' AS pattern),
STRUCT('MEZCAL UNION' AS brand, r'MEZCAL\s*UNION|UNION\s*MEZCAL'AS pattern)
])
)

SELECT
brands.brand,
sales.vendor_name,
COUNT(*) AS transaction_count,
MIN(sales.date) AS first_transaction_date,
MAX(sales.date) AS last_transaction_date,
SUM(sales.bottles_sold) AS total_bottles
FROM `bigquery-public-data.iowa_liquor_sales.sales` AS sales
JOIN brand_patterns AS brands
ON REGEXP_CONTAINS(UPPER(sales.item_description), brands.pattern)
GROUP BY
brands.brand,
sales.vendor_name
ORDER BY
brands.brand,
first_transaction_date;

-- Step 4: Calculate cumulative distinct store coverage by month
-- Complete missing months with zero new stores

WITH brand_patterns AS (
SELECT *
FROM UNNEST([
STRUCT('MR BLACK' AS brand, r'MR\s*BLACK' AS pattern),
STRUCT('STARWARD' AS brand, r'STARWARD' AS pattern),
STRUCT('DON PAPA' AS brand, r'DON\s*PAPA' AS pattern),
STRUCT(
'MEZCAL UNION' AS brand,
r'MEZCAL\s*UNION|UNION\s*MEZCAL' AS pattern
)
])
),

brand_sales AS (
SELECT
brands.brand,
sales.date,
sales.store_number
FROM `bigquery-public-data.iowa_liquor_sales.sales` AS sales
JOIN brand_patterns AS brands
ON REGEXP_CONTAINS(
UPPER(sales.item_description),
brands.pattern
)
WHERE sales.store_number IS NOT NULL
),

first_store_month AS (
SELECT
brand,
store_number,
DATE_TRUNC(MIN(date), MONTH) AS first_month
FROM brand_sales
GROUP BY
brand,
store_number
),

monthly_new_stores AS (
SELECT
brand,
first_month AS month,
COUNT(*) AS new_store_count
FROM first_store_month
GROUP BY
brand,
month
),

brand_bounds AS (
SELECT
brand,
MIN(first_month) AS first_month
FROM first_store_month
GROUP BY brand
),

sample_end AS (
SELECT
MAX(DATE_TRUNC(date, MONTH)) AS last_month
FROM brand_sales
),

complete_months AS (
SELECT
bounds.brand,
month
FROM brand_bounds AS bounds
CROSS JOIN sample_end
CROSS JOIN UNNEST(
GENERATE_DATE_ARRAY(
bounds.first_month,
sample_end.last_month,
INTERVAL 1 MONTH
)
) AS month
)

SELECT
panel.brand,
panel.month,
COALESCE(stores.new_store_count, 0) AS new_store_count,

SUM(COALESCE(stores.new_store_count, 0)) OVER (
PARTITION BY panel.brand
ORDER BY panel.month
) AS cumulative_store_count

FROM complete_months AS panel

LEFT JOIN monthly_new_stores AS stores
ON panel.brand = stores.brand
AND panel.month = stores.month

ORDER BY
panel.brand,
panel.month;

-- Step 5: Calculate monthly bottle purchases by brand
-- Fill missing months with 0 after each brand's first observed transaction

WITH brand_patterns AS (
SELECT *
FROM UNNEST([
STRUCT('MR BLACK' AS brand, r'MR\s*BLACK' AS pattern),
STRUCT('STARWARD' AS brand, r'STARWARD' AS pattern),
STRUCT('DON PAPA' AS brand, r'DON\s*PAPA' AS pattern),
STRUCT(
'MEZCAL UNION' AS brand,
r'MEZCAL\s*UNION|UNION\s*MEZCAL' AS pattern
)
])
),

monthly_sales AS (
SELECT
brands.brand,
DATE_TRUNC(sales.date, MONTH) AS month,
SUM(sales.bottles_sold) AS monthly_bottles_sold
FROM `bigquery-public-data.iowa_liquor_sales.sales` AS sales
JOIN brand_patterns AS brands
ON REGEXP_CONTAINS(
UPPER(sales.item_description),
brands.pattern
)
GROUP BY
brands.brand,
month
),

brand_bounds AS (
SELECT
brand,
MIN(month) AS first_month
FROM monthly_sales
GROUP BY brand
),

sample_end AS (
SELECT
MAX(month) AS last_month
FROM monthly_sales
)

SELECT
bounds.brand,
month,
COALESCE(sales.monthly_bottles_sold, 0) AS monthly_bottles_sold
FROM brand_bounds AS bounds
CROSS JOIN sample_end
CROSS JOIN UNNEST(
GENERATE_DATE_ARRAY(
bounds.first_month,
sample_end.last_month,
INTERVAL 1 MONTH
)
) AS month
LEFT JOIN monthly_sales AS sales
ON bounds.brand = sales.brand
AND month = sales.month
ORDER BY
bounds.brand,
month;

-- Step 6: Calculate account concentration and rank stores by brand
WITH store_sales AS (
SELECT
REGEXP_EXTRACT(UPPER(item_description), r'(MR BLACK|DON PAPA|STARWARD|MEZCAL UNION)')
AS brand,
store_number,
ANY_VALUE(store_name) AS store_name,
SUM(bottles_sold) AS store_bottles
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE
REGEXP_CONTAINS(UPPER(item_description), r'MR BLACK|DON PAPA|STARWARD|MEZCAL UNION')
AND store_number IS NOT NULL
GROUP BY
brand,
store_number)

SELECT
brand,
store_number,
store_name,
store_bottles,
ROUND(100 * store_bottles / SUM(store_bottles) OVER (PARTITION BY brand), 2)
AS share_of_brand_percent,

RANK() OVER (PARTITION BY brand 
ORDER BY store_bottles DESC)
AS account_rank
FROM store_sales
ORDER BY
brand,
account_rank;