-- Phase 2: Create cleaned tables
-- Keep the original source tables unchanged.

-- Remove dependent analytics objects before rebuilding clean tables.
DROP VIEW IF EXISTS analytics.customer_segments_with_web_activity;
DROP VIEW IF EXISTS analytics.customer_360_with_web_activity;
DROP VIEW IF EXISTS analytics.customer_segments;
DROP VIEW IF EXISTS analytics.resolved_orders;
DROP TABLE IF EXISTS analytics.customer_360;
DROP TABLE IF EXISTS analytics.identity_resolution;

-- Drop cleaned tables in reverse dependency order.
DROP TABLE IF EXISTS clean.consent_changes;
DROP TABLE IF EXISTS clean.campaign_events;
DROP TABLE IF EXISTS clean.support_tickets;
DROP TABLE IF EXISTS clean.identity_links;
DROP TABLE IF EXISTS clean.payments;
DROP TABLE IF EXISTS clean.orders;
DROP TABLE IF EXISTS clean.crm_contacts;

CREATE SCHEMA IF NOT EXISTS clean;

-- 1. Clean customer contacts
CREATE TABLE clean.crm_contacts AS
SELECT
    TRIM(contact_id) AS contact_id,
    NULLIF(TRIM(web_user_id), '') AS web_user_id,
    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(last_name), '') AS last_name,
    LOWER(NULLIF(TRIM(email), '')) AS email,
    NULLIF(TRIM(phone), '') AS phone,
    LOWER(NULLIF(TRIM(loyalty_tier), '')) AS loyalty_tier,
    created_at,
    updated_at
FROM public.crm_contacts
WHERE NULLIF(TRIM(contact_id), '') IS NOT NULL;

ALTER TABLE clean.crm_contacts
ADD PRIMARY KEY (contact_id);


-- 2. Clean orders
DROP TABLE IF EXISTS clean.orders;

CREATE TABLE clean.orders AS
SELECT
    TRIM(order_id) AS order_id,
    NULLIF(TRIM(contact_id), '') AS contact_id,
    NULLIF(TRIM(web_user_id), '') AS web_user_id,
    ordered_at,
    LOWER(NULLIF(TRIM(order_status), '')) AS order_status,
    gross_amount,
    UPPER(NULLIF(TRIM(currency_code), '')) AS currency_code,
    source_purchase_items,
    updated_at
FROM public.orders
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;

ALTER TABLE clean.orders
ADD PRIMARY KEY (order_id);

ALTER TABLE clean.orders
ADD CONSTRAINT fk_clean_orders_contact
FOREIGN KEY (contact_id)
REFERENCES clean.crm_contacts(contact_id);


-- 3. Clean payments
DROP TABLE IF EXISTS clean.payments;

CREATE TABLE clean.payments AS
SELECT
    TRIM(payment_id) AS payment_id,
    TRIM(order_id) AS order_id,
    LOWER(NULLIF(TRIM(payment_status), '')) AS payment_status,
    payment_amount,
    UPPER(NULLIF(TRIM(currency_code), '')) AS currency_code,
    updated_at
FROM public.payments
WHERE NULLIF(TRIM(payment_id), '') IS NOT NULL;

ALTER TABLE clean.payments
ADD PRIMARY KEY (payment_id);

ALTER TABLE clean.payments
ADD CONSTRAINT fk_clean_payments_order
FOREIGN KEY (order_id)
REFERENCES clean.orders(order_id);


-- 4. Clean identity links
DROP TABLE IF EXISTS clean.identity_links;

CREATE TABLE clean.identity_links AS
SELECT
    TRIM(link_id) AS link_id,
    NULLIF(TRIM(contact_id), '') AS contact_id,
    NULLIF(TRIM(web_user_id), '') AS web_user_id,
    user_session,
    LOWER(NULLIF(TRIM(verification_method), '')) AS verification_method,
    verified,
    linked_at
FROM public.identity_links
WHERE NULLIF(TRIM(link_id), '') IS NOT NULL;

ALTER TABLE clean.identity_links
ADD PRIMARY KEY (link_id);

ALTER TABLE clean.identity_links
ADD CONSTRAINT fk_clean_identity_contact
FOREIGN KEY (contact_id)
REFERENCES clean.crm_contacts(contact_id);


-- 5. Clean support tickets
DROP TABLE IF EXISTS clean.support_tickets;

CREATE TABLE clean.support_tickets AS
SELECT DISTINCT ON (TRIM(ticket_id))
    TRIM(ticket_id) AS ticket_id,
    LOWER(NULLIF(TRIM(email), '')) AS email,
    NULLIF(TRIM(contact_id), '') AS contact_id,
    LOWER(NULLIF(TRIM(topic), '')) AS topic,
    LOWER(NULLIF(TRIM(status), '')) AS status,
    updated_at
FROM public.support_tickets
WHERE NULLIF(TRIM(ticket_id), '') IS NOT NULL
ORDER BY TRIM(ticket_id), updated_at DESC;

ALTER TABLE clean.support_tickets
ADD PRIMARY KEY (ticket_id);

ALTER TABLE clean.support_tickets
ADD CONSTRAINT fk_clean_tickets_contact
FOREIGN KEY (contact_id)
REFERENCES clean.crm_contacts(contact_id);


-- 6. Clean campaign events
DROP TABLE IF EXISTS clean.campaign_events;

CREATE TABLE clean.campaign_events AS
SELECT
    TRIM(campaign_event_id) AS campaign_event_id,
    NULLIF(TRIM(contact_id), '') AS contact_id,
    LOWER(NULLIF(TRIM(event_type), '')) AS event_type,
    event_time,
    UPPER(NULLIF(TRIM(campaign_id), '')) AS campaign_id
FROM public.campaign_events
WHERE NULLIF(TRIM(campaign_event_id), '') IS NOT NULL;

ALTER TABLE clean.campaign_events
ADD PRIMARY KEY (campaign_event_id);

ALTER TABLE clean.campaign_events
ADD CONSTRAINT fk_clean_campaign_contact
FOREIGN KEY (contact_id)
REFERENCES clean.crm_contacts(contact_id);


-- 7. Clean consent changes
DROP TABLE IF EXISTS clean.consent_changes;

CREATE TABLE clean.consent_changes AS
SELECT
    TRIM(consent_id) AS consent_id,
    TRIM(contact_id) AS contact_id,
    LOWER(NULLIF(TRIM(channel), '')) AS channel,
    LOWER(NULLIF(TRIM(consent_status), '')) AS consent_status,
    updated_at
FROM public.consent_changes
WHERE NULLIF(TRIM(consent_id), '') IS NOT NULL;

ALTER TABLE clean.consent_changes
ADD PRIMARY KEY (consent_id);

ALTER TABLE clean.consent_changes
ADD CONSTRAINT fk_clean_consent_contact
FOREIGN KEY (contact_id)
REFERENCES clean.crm_contacts(contact_id);


-- Report completion
SELECT 'Cleaned tables created successfully' AS result;