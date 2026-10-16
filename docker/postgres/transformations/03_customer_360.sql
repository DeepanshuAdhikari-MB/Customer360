CREATE TABLE IF NOT EXISTS analytics.customer_360 (
    contact_id TEXT PRIMARY KEY,
    web_user_id TEXT,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    loyalty_tier TEXT,

    total_orders BIGINT NOT NULL DEFAULT 0,
    completed_orders BIGINT NOT NULL DEFAULT 0,
    cancelled_orders BIGINT NOT NULL DEFAULT 0,
    completed_order_value NUMERIC(14, 2) NOT NULL DEFAULT 0,

    successful_payments BIGINT NOT NULL DEFAULT 0,
    failed_payments BIGINT NOT NULL DEFAULT 0,
    refunded_payments BIGINT NOT NULL DEFAULT 0,

    support_ticket_count BIGINT NOT NULL DEFAULT 0,
    campaign_event_count BIGINT NOT NULL DEFAULT 0,
    campaign_click_count BIGINT NOT NULL DEFAULT 0,
    campaign_unsubscribe_count BIGINT NOT NULL DEFAULT 0,

    email_consent TEXT,
    last_purchase_at TIMESTAMPTZ,
    profile_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

TRUNCATE TABLE analytics.customer_360;

WITH
order_summary AS (
    SELECT
        resolved_contact_id AS contact_id,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'completed'
        ) AS completed_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'cancelled'
        ) AS cancelled_orders,
        COALESCE(
            SUM(gross_amount) FILTER (
                WHERE order_status = 'completed'
            ),
            0
        ) AS completed_order_value,
        MAX(ordered_at) AS last_purchase_at
    FROM analytics.resolved_orders
    WHERE resolved_contact_id IS NOT NULL
    GROUP BY resolved_contact_id
),
payment_summary AS (
    SELECT
        ro.resolved_contact_id AS contact_id,
        COUNT(*) FILTER (
            WHERE p.payment_status = 'success'
        ) AS successful_payments,
        COUNT(*) FILTER (
            WHERE p.payment_status = 'failed'
        ) AS failed_payments,
        COUNT(*) FILTER (
            WHERE p.payment_status = 'refunded'
        ) AS refunded_payments
    FROM analytics.resolved_orders ro
    JOIN clean.payments p
        ON p.order_id = ro.order_id
    WHERE ro.resolved_contact_id IS NOT NULL
    GROUP BY ro.resolved_contact_id
),
support_summary AS (
    SELECT
        contact_id,
        COUNT(*) AS support_ticket_count
    FROM clean.support_tickets
    WHERE contact_id IS NOT NULL
    GROUP BY contact_id
),
campaign_summary AS (
    SELECT
        contact_id,
        COUNT(*) AS campaign_event_count,
        COUNT(*) FILTER (
            WHERE event_type = 'click'
        ) AS campaign_click_count,
        COUNT(*) FILTER (
            WHERE event_type = 'unsubscribe'
        ) AS campaign_unsubscribe_count
    FROM clean.campaign_events
    WHERE contact_id IS NOT NULL
    GROUP BY contact_id
),
latest_email_consent AS (
    SELECT DISTINCT ON (contact_id)
        contact_id,
        consent_status AS email_consent
    FROM clean.consent_changes
    WHERE channel = 'email'
      AND contact_id IS NOT NULL
    ORDER BY contact_id, updated_at DESC, consent_id DESC
)
INSERT INTO analytics.customer_360 (
    contact_id,
    web_user_id,
    first_name,
    last_name,
    email,
    phone,
    loyalty_tier,
    total_orders,
    completed_orders,
    cancelled_orders,
    completed_order_value,
    successful_payments,
    failed_payments,
    refunded_payments,
    support_ticket_count,
    campaign_event_count,
    campaign_click_count,
    campaign_unsubscribe_count,
    email_consent,
    last_purchase_at,
    profile_updated_at
)
SELECT
    c.contact_id,
    i.web_user_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.loyalty_tier,

    COALESCE(o.total_orders, 0),
    COALESCE(o.completed_orders, 0),
    COALESCE(o.cancelled_orders, 0),
    COALESCE(o.completed_order_value, 0),

    COALESCE(p.successful_payments, 0),
    COALESCE(p.failed_payments, 0),
    COALESCE(p.refunded_payments, 0),

    COALESCE(s.support_ticket_count, 0),
    COALESCE(m.campaign_event_count, 0),
    COALESCE(m.campaign_click_count, 0),
    COALESCE(m.campaign_unsubscribe_count, 0),

    ec.email_consent,
    o.last_purchase_at,
    CURRENT_TIMESTAMP
FROM clean.crm_contacts c
LEFT JOIN analytics.identity_resolution i
    ON i.contact_id = c.contact_id
LEFT JOIN order_summary o
    ON o.contact_id = c.contact_id
LEFT JOIN payment_summary p
    ON p.contact_id = c.contact_id
LEFT JOIN support_summary s
    ON s.contact_id = c.contact_id
LEFT JOIN campaign_summary m
    ON m.contact_id = c.contact_id
LEFT JOIN latest_email_consent ec
    ON ec.contact_id = c.contact_id;