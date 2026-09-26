-- ============================================
-- E-Commerce Customer Churn & Revenue Analysis
-- Analytical SQL Queries
-- ============================================

-- Query 1: Top Revenue-Generating Customers
SELECT 
    u.user_id,
    u.name,
    COUNT(t.transaction_id) AS total_orders,
    SUM(t.total_amount) AS total_spent
FROM users u
JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.name
ORDER BY total_spent DESC
LIMIT 5;


-- Query 2: Churned vs. Active Customers
-- Churn defined as no purchase within 180 days of the dataset's latest transaction date
SELECT 
    u.user_id,
    u.name,
    MAX(t.transaction_date) AS last_purchase_date,
    CASE 
        WHEN MAX(t.transaction_date) < (SELECT MAX(transaction_date) FROM transactions) - INTERVAL '180 days'
        THEN 'Churned'
        ELSE 'Active'
    END AS customer_status
FROM users u
JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.name
ORDER BY last_purchase_date;


-- Query 3: Monthly Revenue Trend
SELECT 
    DATE_TRUNC('month', transaction_date) AS month,
    SUM(total_amount) AS monthly_revenue,
    COUNT(*) AS num_transactions
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY month;


-- Query 4: Revenue by Product Category (with % share of total revenue)
SELECT 
    p.category,
    SUM(t.total_amount) AS category_revenue,
    ROUND(100.0 * SUM(t.total_amount) / (SELECT SUM(total_amount) FROM transactions), 1) AS pct_of_total
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;


-- Query 5: Purchase Frequency — Churned vs. Active Customers
-- Uses LAG() window function to calculate days between each customer's consecutive purchases
WITH purchase_gaps AS (
    SELECT 
        user_id,
        transaction_date,
        transaction_date - LAG(transaction_date) OVER (
            PARTITION BY user_id ORDER BY transaction_date
        ) AS days_since_last_purchase
    FROM transactions
),
customer_status AS (
    SELECT 
        u.user_id,
        u.name,
        CASE 
            WHEN MAX(t.transaction_date) < (SELECT MAX(transaction_date) FROM transactions) - INTERVAL '180 days'
            THEN 'Churned'
            ELSE 'Active'
        END AS status
    FROM users u
    JOIN transactions t ON u.user_id = t.user_id
    GROUP BY u.user_id, u.name
)
SELECT 
    cs.status,
    ROUND(AVG(pg.days_since_last_purchase), 1) AS avg_days_between_purchases
FROM purchase_gaps pg
JOIN customer_status cs ON pg.user_id = cs.user_id
WHERE pg.days_since_last_purchase IS NOT NULL
GROUP BY cs.status;