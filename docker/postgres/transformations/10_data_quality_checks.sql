-- 1. Check for duplicate source customer IDs
SELECT
    'duplicate_source_customer_ids' AS check_name,
    COUNT(*) AS issue_count
FROM (
    SELECT contact_id
    FROM public.crm_contacts
    GROUP BY contact_id
    HAVING COUNT(*) > 1
) duplicates

UNION ALL

-- 2. Check for missing source customer IDs
SELECT
    'missing_source_customer_ids',
    COUNT(*)
FROM public.crm_contacts
WHERE contact_id IS NULL
   OR TRIM(contact_id) = ''

UNION ALL

-- 3. Check for duplicate verified identity mappings
SELECT
    'duplicate_identity_mappings',
    COUNT(*)
FROM (
    SELECT web_user_id
    FROM analytics.identity_resolution
    GROUP BY web_user_id
    HAVING COUNT(*) > 1
) duplicates

UNION ALL

-- 4. Check for negative order amounts
-- 4. Check for negative order amounts
SELECT
    'negative_order_amounts',
    COUNT(*)
FROM public.orders
WHERE gross_amount < 0

UNION ALL

-- 5. Check marketing eligibility for opted-out customers
SELECT
    'opted_out_but_marketing_eligible',
    COUNT(*)
FROM analytics.customer_segments_with_web_activity
WHERE email_consent = 'opted_out'
  AND marketing_eligible = TRUE;