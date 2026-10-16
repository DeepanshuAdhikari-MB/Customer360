CREATE OR REPLACE VIEW analytics.resolved_orders AS
SELECT
    o.order_id,
    COALESCE(o.contact_id, i.contact_id) AS resolved_contact_id,
    o.contact_id AS original_contact_id,
    o.web_user_id,
    o.ordered_at,
    o.order_status,
    o.gross_amount,
    o.currency_code,
    o.source_purchase_items,
    CASE
        WHEN o.contact_id IS NOT NULL
            THEN 'original_contact_id'
        WHEN i.contact_id IS NOT NULL
            THEN 'verified_identity_match'
        ELSE 'unresolved'
    END AS resolution_method
FROM clean.orders o
LEFT JOIN analytics.identity_resolution i
    ON i.web_user_id = o.web_user_id
   AND o.contact_id IS NULL;