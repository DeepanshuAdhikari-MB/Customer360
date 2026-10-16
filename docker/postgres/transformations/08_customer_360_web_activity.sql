CREATE OR REPLACE VIEW analytics.customer_360_with_web_activity AS
SELECT
    c.*,

    COALESCE(w.total_views, 0) AS total_views,
    COALESCE(w.total_cart_events, 0) AS total_cart_events,
    COALESCE(w.total_purchase_events, 0) AS total_web_purchase_events,

    w.first_event_at,
    w.last_event_at

FROM analytics.customer_360 c

LEFT JOIN analytics.identity_resolution i
    ON i.contact_id = c.contact_id

LEFT JOIN analytics.web_activity w
    ON w.web_user_id = i.web_user_id;