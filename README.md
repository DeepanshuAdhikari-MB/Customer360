# Customer360 Data Engineering Project

## 1. Overview

Customer360 is a data engineering project that combines customer, order, payment, identity, consent, and website activity data into unified customer profiles.

The project demonstrates data ingestion, ETL pipelines, SQL transformations, identity resolution, customer segmentation, data quality validation, and business analytics.

The main goal is to create a unified view of customers by combining business data with their website activity.

## 2. Technology Stack

- **Python:** Data ingestion and pipeline orchestration.
- **PostgreSQL:** Business data storage, SQL transformations, and customer profiles.
- **ClickHouse:** Large-scale website event storage and aggregation.
- **Docker Compose:** Runs PostgreSQL and ClickHouse in containers.
- **SQL:** Data cleaning, transformations, segmentation, and analytics.
- **CSV and JSONL:** Source data formats.
- **pytest:** Automated testing of pipeline validation logic.
- **Git and GitHub:** Version control and project hosting.

## 3. Architecture

### Business Data Pipeline

```text
Business CSV and JSONL Files
             |
             v
     Python Ingestion
             |
             v
         PostgreSQL
             |
             v
   Data Cleaning and SQL
      Transformations
             |
             v
    Identity Resolution
             |
             v
      Order Resolution
             |
             v
     Customer 360 Profiles
             |
             v
   Customer Segmentation
             |
             v
     Business Analytics
```

### Website Activity Pipeline

```text
Website Event CSV
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
     PostgreSQL
        |
        v
Customer 360 with Web Activity
        |
        v
Customer Segmentation
```

PostgreSQL stores the business data and unified customer profiles. ClickHouse handles the large volume of website events.

Python connects the ingestion and processing steps, while SQL performs most of the data transformations.

## 4. Project Features

- Ingest business data from CSV and JSONL files.
- Load source data into PostgreSQL.
- Process large website event datasets using batch ingestion.
- Store website events in ClickHouse.
- Clean and transform source data using SQL.
- Resolve website identities to customer contacts.
- Link orders to customer profiles where possible.
- Build unified Customer 360 profiles.
- Aggregate customer website activity.
- Segment customers using purchase and web activity.
- Validate record counts and data quality.
- Generate business insights using SQL queries.
- Orchestrate the main business pipeline with Python.
- Run automated tests for pipeline validation logic.

## 5. Verified Results

The following results were verified in the current project state.

| Metric | Result |
|---|---:|
| Source contacts | 12,292 |
| Clean contacts | 12,292 |
| Identity mappings | 8,571 |
| Total orders | 4,009 |
| Resolved orders | 3,715 |
| Unresolved orders | 294 |
| Customer 360 profiles | 12,292 |
| Customer segments | 6 |
| Website users aggregated | 3,022,290 |
| Website events processed | 42,448,764 |

The order resolution rate is approximately **92.67%**.

The unresolved order count is 294, meaning some orders could not be linked to customer profiles using the implemented identity resolution rules.

Website event counts represent recorded website actions, not necessarily completed business orders.

## 6. Customer Segmentation Results

The project classifies customer profiles into six segments using SQL rules.

| Segment | Customers |
|---|---:|
| browser_only | 6,807 |
| no_purchase | 3,317 |
| high_value | 1,281 |
| cart_abandoner | 471 |
| inactive_customer | 269 |
| active_customer | 147 |
| **Total** | **12,292** |

### Segment Meaning

- **browser_only:** Customers with website views but no recorded completed orders or cart events.
- **no_purchase:** Customers who do not meet the rules for the other segments.
- **high_value:** Customers whose completed order value meets the configured high-value threshold.
- **cart_abandoner:** Customers with cart activity but no recorded completed orders.
- **inactive_customer:** Customers with completed orders who do not qualify for a higher-priority segment.
- **active_customer:** Customers with completed orders and a purchase date within the configured activity period, provided they do not qualify for a higher-priority segment.

The SQL uses ordered `CASE` conditions. Therefore, a customer who matches more than one condition is assigned to the first matching segment.

These are project-specific analytical definitions, not universal definitions of customer behavior.

## 7. Data Quality Validation

The main pipeline successfully passed five implemented data quality checks.

| Check | Result |
|---|---:|
| Duplicate source customer IDs | 0 |
| Missing source customer IDs | 0 |
| Duplicate identity mappings | 0 |
| Negative order amounts | 0 |
| Opted-out customers marked marketing eligible | 0 |

The pipeline also validates expected record counts for source contacts, cleaned contacts, identity resolution, resolved orders, Customer 360 profiles, and customer segments.

The pipeline stops with an error if the configured record-count or data quality validations fail.

## 8. Prerequisites

Before running the project, configure:

- Python 3.14.4 (the version used to test this project).
- Docker.
- Docker Compose.
- A terminal.
- The project source files.
- The required raw input data.
- Sufficient disk space for the source data and database storage.

The website event dataset is large, so ensure adequate storage before processing it.

## 9. Project Setup

Run the following commands from your terminal.

### Step 1: Navigate to the project

```bash
cd ~/Projects/customer360
```

### Step 2: Activate the virtual environment

```bash
source .venv/bin/activate
```

### Step 3: Install Python dependencies

```bash
pip install -r requirements.txt
```

### Step 4: Install the project package

```bash
pip install -e .
```

### Step 5: Configure environment variables

Create or configure the `.env` file using `.env.example` as a reference.

Set the PostgreSQL and ClickHouse database credentials required by `docker-compose.yml`.

Do not commit real passwords, API keys, or other secrets.

### Step 6: Start the databases

```bash
docker compose up -d
```

Check the container status:

```bash
docker compose ps
```

Ensure PostgreSQL and ClickHouse are running before executing database-dependent operations.

### Step 7: Run the business data pipeline

```bash
python -m customer360.pipeline.run_pipeline
```

The main pipeline:

1. Ingests the business source data.
2. Executes SQL cleaning and transformation scripts.
3. Builds identity resolution mappings.
4. Resolves orders to customer profiles where possible.
5. Builds Customer 360 profiles.
6. Updates web activity and customer segmentation views.
7. Validates record counts.
8. Executes data quality checks.

The pipeline reports success when its configured validations pass.

## 10. Website Event Processing

The project processes website event data separately from the main business pipeline.

### Required Dataset

The ingestion script expects the public October 2019 e-commerce behavior dataset in this location:

```text
~/Downloads/archive(1).zip
```

The ZIP archive must contain:

```text
2019-Oct.csv
```

The script currently uses this local path directly. If your archive is stored elsewhere or has a different filename, update `ZIP_PATH` in:

```text
src/customer360/ingestion/load_web_events.py
```

The large dataset is not included in the project repository. Obtain it from the original public dataset source and review its applicable usage terms before redistribution.

### Run Website Event Ingestion

From the project root, activate the virtual environment and run:

```bash
python -m customer360.ingestion.load_web_events
```

The script processes the data in batches and maintains a checkpoint at:

```text
data/raw/web_events_checkpoint.json
```

Check the script's supported command-line options before using `--limit` or `--resume`.

The checkpoint tracks ingestion progress. Keep it locally rather than publishing it as project source code.

### Current Verified Results

The processed October dataset contains 42,448,764 website events. The existing PostgreSQL web activity table contains 3,022,290 aggregated website users.

Website event ingestion is separate from the main business pipeline and does not need to be repeated when running the business transformations.

## 11. Business Analytics

The SQL analytics file is:

```text
sql/analytics/customer_insights.sql
```

Run the analytics queries from the project root:

```bash
docker compose exec -T postgres psql -U c360user -d customer360 < sql/analytics/customer_insights.sql
```

The queries report:

- Top customer profiles by completed order value.
- Customer counts by segment.
- Unresolved orders grouped by status.
- Order identity resolution statistics.
- Marketing eligibility by customer segment.

### Order Resolution Results

| Metric | Result |
|---|---:|
| Total orders | 4,009 |
| Resolved orders | 3,715 |
| Unresolved orders | 294 |
| Resolution rate | 92.67% |
| Unresolved rate | 7.33% |

Order resolution helps determine how many orders can be associated with known customer profiles.

### Marketing Eligibility

The current segmentation logic marks customers as marketing eligible when their modeled email consent is `opted_in`.

This is a project-specific eligibility rule and is not a substitute for complete real-world marketing compliance checks.

## 12. Automated Testing

The project includes four automated tests for pipeline validation logic.

The tests cover:

1. Successful record-count validation.
2. Failure when a record count is incorrect.
3. Successful data quality validation.
4. Failure when a data quality issue is detected.

### Run the Tests

Activate the virtual environment and install the dependencies:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

Run the test suite:

```bash
python -m pytest -v
```

The current test suite contains four tests. These tests use mocked database connections to test validation behavior without modifying the actual database.

A successful run should report:

```text
4 passed
```

The tests validate pipeline checking logic; they do not replace integration tests against real database instances.

## 13. Documentation

Additional project documentation is available at:

```text
docs/project_overview.md
```

This document provides a shorter overview of the architecture, processing steps, and verified results.

## 14. Current Limitations

- Some orders cannot be linked to customer profiles.
- Customer segments depend on the implemented SQL rules and their priority.
- Website user identities are not available for every customer.
- The website activity dataset represents only part of a customer's potential activity.
- Marketing eligibility is based on the project's email consent rules and is not a substitute for all real-world compliance checks.
- Website event counts represent events rather than confirmed business orders.
- The current test suite focuses on pipeline validation logic rather than every ingestion and transformation component.
- The reported results describe the currently processed dataset.

## 15. Future Improvements

- Add automated tests for data transformations and ingestion.
- Improve pipeline logging and error handling.
- Add monitoring and failure notifications.
- Optimize large-scale web activity aggregation to reduce memory usage.
- Add scheduled pipeline execution.
- Add incremental processing for newly arriving source data.
- Improve handling and investigation of unresolved identities and orders.
- Create a dashboard for customer and segment analytics.
- Add integration tests for PostgreSQL and ClickHouse.
- Add CI automation to run tests and validation checks.

## 16. Project Summary

Customer360 demonstrates an end-to-end data engineering workflow using Python, PostgreSQL, ClickHouse, Docker Compose, and SQL.

It combines business source data with large-scale website activity, builds unified customer profiles, applies customer segmentation rules, and validates the pipeline through record-count checks, data quality checks, and automated tests.
