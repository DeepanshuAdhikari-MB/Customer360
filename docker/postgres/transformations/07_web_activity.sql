CREATE TABLE IF NOT EXISTS analytics.web_activity (
    web_user_id TEXT PRIMARY KEY,

    total_views BIGINT NOT NULL DEFAULT 0,
    total_cart_events BIGINT NOT NULL DEFAULT 0,
    total_purchase_events BIGINT NOT NULL DEFAULT 0,

    first_event_at TIMESTAMPTZ,
    last_event_at TIMESTAMPTZ,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);