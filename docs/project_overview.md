# Customer360 Data Engineering Project

## 1. Project Overview

Customer360 is a data engineering project that combines customer,
order, payment, identity, consent, and website activity data to build
a unified customer profile.

The project processes business data, resolves customer identities,
creates customer segments, and produces business analytics.

## 2. Technology Stack

- Python: Data ingestion and pipeline orchestration
- PostgreSQL: Business data, transformations, and customer profiles
- ClickHouse: Large-scale website event storage and aggregation
- Docker Compose: Runs PostgreSQL and ClickHouse
- SQL: Data cleaning, transformations, segmentation, and analytics
- CSV and JSONL: Input data formats

## 3. High-Level Architecture

Source Business Data
        |
        v
Python Data Ingestion
        |
        v
PostgreSQL
        |
        v
Data Cleaning and Transformations
        |
        v
Identity Resolution
        |
        v
Customer 360 Profiles
        |
        v
Customer Segmentation
        |
        v
Business Analytics

Website Events
        |
        v
Python Batch Ingestion
        |
        v
ClickHouse
        |
        v
Web Activity Aggregation
        |
        v
PostgreSQL Customer Profiles

## 4. Main Pipeline Steps

1. Load raw business data into PostgreSQL.
2. Clean source data and prepare analytics tables.
3. Resolve web identities to customer contacts.
4. Link orders to customer profiles where possible.
5. Build unified Customer 360 profiles.
6. Create customer segments.
7. Aggregate website events by web user.
8. Connect website activity to customer profiles.
9. Run record-count validations and data quality checks.

## 5. Verified Results

- Source contacts: 12,292
- Clean contacts: 12,292
- Verified identity mappings: 8,571
- Total orders: 4,009
- Resolved orders: 3,715
- Unresolved orders: 294
- Customer 360 profiles: 12,292

## 6. Customer Segments

| Segment | Customers |
|---|---:|
| browser_only | 6,807 |
| no_purchase | 3,317 |
| high_value | 1,281 |
| cart_abandoner | 471 |
| inactive_customer | 269 |
| active_customer | 147 |
| Total | 12,292 |

## 7. Data Quality Results

The pipeline passed all five implemented data quality checks:

- Duplicate source customer IDs: 0
- Missing source customer IDs: 0
- Duplicate identity mappings: 0
- Negative order amounts: 0
- Opted-out customers marked marketing eligible: 0

## 8. Business Insights

- The browser_only segment is the largest customer segment.
- The pipeline resolved 3,715 of 4,009 orders to customer profiles.
- There are 294 unresolved orders requiring investigation.
- Customer segmentation can help businesses understand purchasing
  behavior and prioritize further analysis.
- Marketing eligibility is based on the project's email consent rules.

## 9. Running the Pipeline

Activate the virtual environment and navigate to the project root.

Run:

    python -m customer360.pipeline.run_pipeline

The pipeline loads business data, executes transformations,
validates record counts, and runs data quality checks.

## 10. Running Business Analytics

Run the reusable analytics SQL file from the project root:

    docker compose exec -T postgres psql -U c360user -d customer360 < sql/analytics/customer_insights.sql

## 11. Current Limitations

- Some orders cannot be linked to customer profiles.
- Customer segments depend on the rules implemented in SQL.
- The current results describe the available dataset, not necessarily
  a customer's complete real-world behavior.
- Marketing eligibility must be checked against applicable consent
  and suppression requirements before a real campaign.
