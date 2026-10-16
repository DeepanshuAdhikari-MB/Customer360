CREATE OR REPLACE VIEW analytics.customer_segments_with_web_activity AS
SELECT
    contact_id,
    first_name,
    last_name,
    email,
    loyalty_tier,

    total_orders,
    completed_orders,
    completed_order_value,

    total_views,
    total_cart_events,
    total_web_purchase_events,

    last_purchase_at,
    email_consent,

    CASE
        WHEN completed_order_value >= 100
            THEN 'high_value'

        WHEN last_purchase_at >= TIMESTAMPTZ '2019-10-16 00:00:00+00'
            AND completed_orders > 0
            THEN 'active_customer'

        WHEN total_cart_events > 0
            AND completed_orders = 0
            THEN 'cart_abandoner'

        WHEN total_views > 0
            AND total_cart_events = 0
            AND completed_orders = 0
            THEN 'browser_only'

        WHEN completed_orders > 0
            THEN 'inactive_customer'

        ELSE 'no_purchase'
    END AS customer_segment,

    (email_consent = 'opted_in') AS marketing_eligible

FROM analytics.customer_360_with_web_activity;