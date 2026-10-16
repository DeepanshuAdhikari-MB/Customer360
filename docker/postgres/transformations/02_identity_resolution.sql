CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.identity_resolution (
    web_user_id TEXT PRIMARY KEY,
    contact_id TEXT NOT NULL,
    verification_method TEXT,
    resolved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_identity_contact
        FOREIGN KEY (contact_id)
        REFERENCES clean.crm_contacts(contact_id),

    CONSTRAINT uq_identity_contact
        UNIQUE (contact_id)
);

INSERT INTO analytics.identity_resolution (
    web_user_id,
    contact_id,
    verification_method
)
SELECT
    web_user_id,
    contact_id,
    verification_method
FROM clean.identity_links
WHERE verified = TRUE
ON CONFLICT (web_user_id)
DO UPDATE SET
    contact_id = EXCLUDED.contact_id,
    verification_method = EXCLUDED.verification_method,
    resolved_at = CURRENT_TIMESTAMP;