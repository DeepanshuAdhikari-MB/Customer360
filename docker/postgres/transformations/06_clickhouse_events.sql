CREATE TABLE IF NOT EXISTS customer360.web_events
(
    event_time DateTime('UTC'),
    event_type LowCardinality(String),

    product_id Nullable(UInt64),
    category_id Nullable(UInt64),

    category_code Nullable(String),
    brand Nullable(String),

    price Nullable(Decimal(12, 2)),

    user_id UInt64,
    user_session Nullable(String)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_time)
ORDER BY (event_time, user_id, event_type);