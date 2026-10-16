-- 1. CRM contacts
CREATE TABLE IF NOT EXISTS crm_contacts (
    contact_id VARCHAR(20) PRIMARY KEY,
    web_user_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    loyalty_tier VARCHAR(50),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);

-- 2. Orders
CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(20) PRIMARY KEY,
    contact_id VARCHAR(20),
    web_user_id VARCHAR(50),
    ordered_at TIMESTAMPTZ,
    order_status VARCHAR(50),
    gross_amount NUMERIC(12, 2),
    currency_code VARCHAR(10),
    source_purchase_items INTEGER,
    updated_at TIMESTAMPTZ,
    CONSTRAINT fk_orders_contact
        FOREIGN KEY (contact_id)
        REFERENCES crm_contacts(contact_id)
);

-- 3. Payments
CREATE TABLE IF NOT EXISTS payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    payment_status VARCHAR(50),
    payment_amount NUMERIC(12, 2),
    currency_code VARCHAR(10),
    updated_at TIMESTAMPTZ,
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- 4. Identity links
CREATE TABLE IF NOT EXISTS identity_links (
    link_id VARCHAR(20) PRIMARY KEY,
    contact_id VARCHAR(20),
    web_user_id VARCHAR(50),
    user_session UUID,
    verification_method VARCHAR(100),
    verified BOOLEAN,
    linked_at TIMESTAMPTZ,
    CONSTRAINT fk_identity_contact
        FOREIGN KEY (contact_id)
        REFERENCES crm_contacts(contact_id)
);

-- 5. Support tickets
CREATE TABLE IF NOT EXISTS support_tickets (
    ticket_id VARCHAR(20) PRIMARY KEY,
    email VARCHAR(255),
    contact_id VARCHAR(20),
    topic VARCHAR(100),
    status VARCHAR(50),
    updated_at TIMESTAMPTZ,
    CONSTRAINT fk_ticket_contact
        FOREIGN KEY (contact_id)
        REFERENCES crm_contacts(contact_id)
);

-- 6. Campaign events
CREATE TABLE IF NOT EXISTS campaign_events (
    campaign_event_id VARCHAR(20) PRIMARY KEY,
    contact_id VARCHAR(20),
    event_type VARCHAR(50),
    event_time TIMESTAMPTZ,
    campaign_id VARCHAR(100),
    CONSTRAINT fk_campaign_contact
        FOREIGN KEY (contact_id)
        REFERENCES crm_contacts(contact_id)
);

-- 7. Consent changes
CREATE TABLE IF NOT EXISTS consent_changes (
    consent_id VARCHAR(20) PRIMARY KEY,
    contact_id VARCHAR(20),
    channel VARCHAR(50),
    consent_status VARCHAR(50),
    updated_at TIMESTAMPTZ,
    CONSTRAINT fk_consent_contact
        FOREIGN KEY (contact_id)
        REFERENCES crm_contacts(contact_id)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_crm_email
    ON crm_contacts(email);

CREATE INDEX IF NOT EXISTS idx_crm_web_user
    ON crm_contacts(web_user_id);

CREATE INDEX IF NOT EXISTS idx_orders_contact
    ON orders(contact_id);

CREATE INDEX IF NOT EXISTS idx_orders_ordered_at
    ON orders(ordered_at);

CREATE INDEX IF NOT EXISTS idx_payments_order
    ON payments(order_id);

CREATE INDEX IF NOT EXISTS idx_identity_web_user
    ON identity_links(web_user_id);

CREATE INDEX IF NOT EXISTS idx_campaign_contact
    ON campaign_events(contact_id);

CREATE INDEX IF NOT EXISTS idx_consent_contact
    ON consent_changes(contact_id);