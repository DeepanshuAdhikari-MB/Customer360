-- 1. Top 10 highest-value customers
SELECT
    contact_id,
    completed_orders,
    completed_order_value,
    last_purchase_at
FROM analytics.customer_360
ORDER BY completed_order_value DESC
LIMIT 10;


-- 2. Customer segment counts
SELECT
    customer_segment,
    COUNT(*) AS customer_count
FROM analytics.customer_segments_with_web_activity
GROUP BY customer_segment
ORDER BY customer_count DESC;


-- 3. Customers with unresolved orders
SELECT
    resolution_method,
    order_status,
    COUNT(*) AS order_count
FROM analytics.resolved_orders
WHERE resolved_contact_id IS NULL
GROUP BY resolution_method, order_status
ORDER BY order_count DESC;


-- 4. Order identity resolution summary
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE resolved_contact_id IS NOT NULL
    ) AS resolved_orders,
    COUNT(*) FILTER (
        WHERE resolved_contact_id IS NULL
    ) AS unresolved_orders
FROM analytics.resolved_orders;


-- 5. Marketing eligibility by customer segment
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE marketing_eligible
    ) AS marketing_eligible_customers
FROM analytics.customer_segments_with_web_activity
GROUP BY customer_segment
ORDER BY total_customers DESC;