-- ============================================================================
-- Capstone Project: Mamaearth Returns & Growth Intelligence Pipeline
-- Part 1: SQL Relational Layer & Reporting
-- Task 3: Nine Business Reports (sql/reports.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Report (a): Order Totals (2 marks)
-- Compute total orders, total revenue, and average order value.
-- Revenue per row: quantity * price * (1 - COALESCE(discount_pct, 0)/100.0)
-- Float division (100.0) ensures accurate decimal calculations.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT:
total_orders | total_revenue | avg_order_value
-------------+---------------+----------------
180          | 99860.20      | 554.78
*/
SELECT 
    COUNT(*) AS total_orders,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_revenue,
    ROUND(AVG(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id;


-- ----------------------------------------------------------------------------
-- Report (b): COUNT(*) vs COUNT(column) (2 marks)
-- Demonstrates difference between COUNT(*) and COUNT(col) on nullable ratings.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT:
total_orders | rated_orders | unrated_orders
-------------+--------------+---------------
180          | 165          | 15
*/
SELECT 
    COUNT(*) AS total_orders,
    COUNT(rating) AS rated_orders,
    COUNT(*) - COUNT(rating) AS unrated_orders
FROM orders;


-- ----------------------------------------------------------------------------
-- Report (c): Zero-Order Customers (3 marks)
-- Method 1: LEFT JOIN with HAVING COUNT(order_id) = 0
-- Method 2: NOT IN subquery
-- Both methods independently verify that customer C045 (Vihaan) has placed 0 orders.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT (Method 1 - LEFT JOIN):
customer_id | name
------------+-------
C045        | Vihaan
*/
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) = 0;

/*
EXACT OUTPUT (Method 2 - NOT IN):
customer_id | name
------------+-------
C045        | Vihaan
*/
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (SELECT DISTINCT customer_id FROM orders);


-- ----------------------------------------------------------------------------
-- Report (d): High Return Rate Cities (> 20%) (3 marks)
-- Groups by city, computes total orders, returned orders, and return rate %.
-- Filters with HAVING return_rate_pct > 20 and orders descending.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT:
city      | total_orders | returned_orders | return_rate_pct
----------+--------------+-----------------+----------------
Jaipur    | 19           | 8               | 42.1
Lucknow   | 49           | 15              | 30.6
Bangalore | 33           | 8               | 24.2
*/
SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.returned) AS returned_orders,
    ROUND(100.0 * SUM(o.returned) / COUNT(o.order_id), 1) AS return_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.city
HAVING return_rate_pct > 20
ORDER BY return_rate_pct DESC;


-- ----------------------------------------------------------------------------
-- Report (e): Customer Spending Ranking (3 marks)
-- Query 1: Top 5 customers by total spend.
-- Query 2: Ranks 3 to 5 using LIMIT 3 OFFSET 2.
-- Note on tie-breaker: 'customer_id ASC' guarantees deterministic ordering when total_spend is identical.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT (Top 5 Customers):
customer_id | name    | total_spend
------------+---------+------------
C043        | Reyansh | 12920.00
C026        | Isha    | 8371.60
C008        | Meera   | 4564.60
C011        | Arjun   | 4111.00
C042        | Sanya   | 3785.00
*/
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 5;

/*
EXACT OUTPUT (Ranks 3 to 5 via OFFSET 2):
customer_id | name    | total_spend
------------+---------+------------
C008        | Meera   | 4564.60
C011        | Arjun   | 4111.00
C042        | Sanya   | 3785.00
*/
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 3 OFFSET 2;


-- ----------------------------------------------------------------------------
-- Report (f): Product Category Breakdown (3-table JOIN) (3 marks)
-- Joins orders, products, and customers to aggregate order count and revenue by category.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT:
category     | order_count | category_revenue
-------------+-------------+-----------------
Haircare     | 54          | 44956.10
Skincare     | 60          | 27346.00
Babycare     | 30          | 16805.00
PersonalCare | 36          | 10753.10
*/
SELECT 
    p.category,
    COUNT(o.order_id) AS order_count,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS category_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY p.category
ORDER BY category_revenue DESC;


-- ----------------------------------------------------------------------------
-- Report (g): Pattern Matching with LIKE (2 marks)
-- Returns customers whose name starts with 'A'.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT (10 rows):
customer_id | name    | city      | signup_date
------------+---------+-----------+------------
C001        | Aarav   | Mumbai    | 2026-01-07
C003        | Aditi   | Mumbai    | 2026-06-23
C004        | Ananya  | Lucknow   | 2026-01-23
C011        | Arjun   | Bangalore | 2026-03-13
C021        | Aryan   | Bangalore | 2026-02-11
C030        | Anika   | Bangalore | 2026-02-24
C031        | Aditya  | Jaipur    | 2026-06-14
C036        | Aisha   | Delhi     | 2026-05-11
C041        | Ayaan   | Lucknow   | 2026-01-03
C044        | Aria    | Bangalore | 2026-04-22
*/
SELECT customer_id, name, city, signup_date
FROM customers
WHERE name LIKE 'A%'
ORDER BY customer_id ASC;


-- ----------------------------------------------------------------------------
-- Report (h): Distinct Acquisition Sources (1 mark)
-- Returns all unique customer acquisition channels.
-- ----------------------------------------------------------------------------
/*
EXACT OUTPUT (4 distinct values):
acquisition_source
------------------
Ad
Organic
Referral
Social
*/
SELECT DISTINCT acquisition_source
FROM customers
ORDER BY acquisition_source ASC;


-- ----------------------------------------------------------------------------
-- Report (i): Schema Alteration & Conditional Update (1 mark)
-- Adds loyalty_tier column and updates with CASE expression (Tier 1 = Gold, Else Silver).
-- ----------------------------------------------------------------------------
-- Step 1: Add loyalty_tier column
ALTER TABLE customers ADD COLUMN loyalty_tier VARCHAR(10);

-- Step 2: Populate loyalty_tier conditionally without WHERE clause
UPDATE customers
SET loyalty_tier = CASE 
    WHEN city_tier = 1 THEN 'Gold' 
    ELSE 'Silver' 
END;

/*
EXACT OUTPUT (Verification Query):
loyalty_tier | count
-------------+------
Gold         | 28
Silver       | 17
*/
SELECT loyalty_tier, COUNT(*) AS count
FROM customers
GROUP BY loyalty_tier
ORDER BY loyalty_tier ASC;
