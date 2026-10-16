CREATE OR REPLACE VIEW analytics.customer_segments AS
SELECT
    contact_id,
    web_user_id,
    first_name,
    last_name,
    email,
    loyalty_tier,

    total_orders,
    completed_orders,
    completed_order_value,
    last_purchase_at,
    email_consent,

    CASE
        WHEN completed_orders = 0
            THEN 'no_purchase'

        WHEN completed_order_value >= 100
            THEN 'high_value'

        WHEN last_purchase_at >=
             TIMESTAMPTZ '2019-10-16 00:00:00+00'
            THEN 'active_customer'

        ELSE 'inactive_customer'
    END AS customer_segment,

    CASE
        WHEN email_consent = 'opted_in'
            THEN TRUE
        ELSE FALSE
    END AS marketing_eligible

FROM analytics.customer_360;