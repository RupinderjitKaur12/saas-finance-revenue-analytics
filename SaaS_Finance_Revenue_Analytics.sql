/*
SaaS Finance & Revenue Analytics Project

Objective:
Analyze customer revenue, invoices, collections,
outstanding receivables and AR aging using MySQL.

Skills demonstrated:
JOINs
GROUP BY
CASE
HAVING
CTEs
Window Functions
DATEDIFF
COALESCE
LAG
RANK
*/


-- Query 1: Customer count by segment
-- Purpose: Understand how the customer base is distributed across segments.
SELECT
    segment,
    COUNT(customer_id) AS number_of_customers
FROM customers
GROUP BY segment;


-- Query 2: Total invoice value by customer segment
-- Purpose: Compare total billed revenue across customer segments.
SELECT
    c.segment,
    SUM(i.invoice_amount) AS total_invoice_value
FROM customers c
INNER JOIN invoices i
    ON c.customer_id = i.customer_id
GROUP BY c.segment
ORDER BY total_invoice_value DESC;


-- Query 3: Average invoice amount by customer segment
-- Purpose: Compare the average invoice size across customer segments.
SELECT
    c.segment,
    AVG(i.invoice_amount) AS average_invoice_amount
FROM customers c
INNER JOIN invoices i
    ON c.customer_id = i.customer_id
GROUP BY c.segment
ORDER BY average_invoice_amount DESC;


-- Query 4: Invoice count by status
-- Purpose: Understand the distribution of Paid, Open and Partially Paid invoices.
SELECT
    invoice_status,
    COUNT(invoice_id) AS number_of_invoices
FROM invoices
GROUP BY invoice_status
ORDER BY number_of_invoices DESC;


-- Query 5: Total invoice value vs amount collected
-- Purpose: Compare total billed value with actual cash collected.
SELECT
    SUM(i.invoice_amount) AS total_invoice_value,
    SUM(COALESCE(p.amount_paid, 0)) AS total_amount_collected
FROM invoices i
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id;


-- Query 6: Outstanding AR by customer segment
-- Purpose: Identify which customer segments have the highest unpaid receivables.
SELECT
    c.segment,
    SUM(i.invoice_amount - COALESCE(p.amount_paid, 0)) AS outstanding_amount
FROM customers c
INNER JOIN invoices i
    ON c.customer_id = i.customer_id
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
GROUP BY c.segment
ORDER BY outstanding_amount DESC;

-- Query 7: Outstanding AR by aging bucket
-- Purpose: Analyze overdue receivables by how long invoices have been past due.
SELECT
    CASE
        WHEN DATEDIFF('2026-10-01', i.due_date) BETWEEN 1 AND 30
            THEN '0-30 days overdue'
        WHEN DATEDIFF('2026-10-01', i.due_date) BETWEEN 31 AND 60
            THEN '31-60 days overdue'
        WHEN DATEDIFF('2026-10-01', i.due_date) BETWEEN 61 AND 90
            THEN '61-90 days overdue'
        WHEN DATEDIFF('2026-10-01', i.due_date) > 90
            THEN '90+ days overdue'
    END AS aging_bucket,
    SUM(i.invoice_amount - COALESCE(p.amount_paid, 0)) AS outstanding_amount
FROM invoices i
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
WHERE DATEDIFF('2026-10-01', i.due_date) > 0
GROUP BY aging_bucket
ORDER BY outstanding_amount DESC;


-- Query 8: Top 10 customers by total invoice value
-- Purpose: Identify the highest-value customers based on total billed revenue.
SELECT
    c.customer_id,
    c.customer_name,
    c.segment,
    SUM(i.invoice_amount) AS total_invoice_value
FROM customers c
INNER JOIN invoices i
    ON c.customer_id = i.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.segment
ORDER BY total_invoice_value DESC
LIMIT 10;


-- Query 9: Monthly invoice trend
-- Purpose: Track billed revenue over time and identify monthly trends.
SELECT
    YEAR(invoice_date) AS invoice_year,
    MONTH(invoice_date) AS invoice_month,
    SUM(invoice_amount) AS monthly_invoice_value
FROM invoices
GROUP BY
    YEAR(invoice_date),
    MONTH(invoice_date)
ORDER BY
    invoice_year,
    invoice_month;


-- Query 10: Month-over-month invoice value change
-- Purpose: Compare each month's billed revenue with the previous month.
WITH monthly_revenue AS (SELECT
                           YEAR(invoice_date) AS invoice_year,
                           MONTH(invoice_date) AS invoice_month,
                           SUM(invoice_amount) AS monthly_invoice_value
                         FROM invoices
                         GROUP BY
                            YEAR(invoice_date),
                            MONTH(invoice_date))

SELECT
    invoice_year,
    invoice_month,
    monthly_invoice_value,
    LAG(monthly_invoice_value) OVER (ORDER BY invoice_year, invoice_month) AS previous_month_value,
        monthly_invoice_value - LAG(monthly_invoice_value) OVER (ORDER BY invoice_year, invoice_month) AS month_over_month_change
FROM monthly_revenue
ORDER BY
    invoice_year,
    invoice_month;


-- Query 11: Rank customers by total invoice value
-- Purpose: Rank customers from highest to lowest based on billed revenue.
WITH customer_revenue AS (SELECT
                         c.customer_id,
                         c.customer_name,
                         c.segment,
                         SUM(i.invoice_amount) AS total_invoice_value
                      FROM customers c
                      INNER JOIN invoices i
                      ON c.customer_id = i.customer_id
                      GROUP BY
                          c.customer_id,
                          c.customer_name,
                          c.segment)

SELECT
    customer_id,
    customer_name,
    segment,
    total_invoice_value,
    RANK() OVER (ORDER BY total_invoice_value DESC) AS customer_rank
FROM customer_revenue
ORDER BY customer_rank;


/*
Project Summary:
This project analyzes a fictional SaaS business using MySQL.

Key areas covered:
- Customer segmentation
- Invoice analysis
- Collections
- Outstanding receivables
- AR aging
- Monthly revenue trends
- Customer ranking

Advanced SQL used:
- CTEs
- Window functions
- LAG
- RANK
- CASE
- DATEDIFF
- COALESCE
*/


