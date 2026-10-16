import os
import subprocess
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[3]

load_dotenv(ROOT_DIR / ".env")

TRANSFORM_DIR = ROOT_DIR / "docker" / "postgres" / "transformations"


def get_connection():
    """Create a connection to PostgreSQL."""
    return psycopg.connect(
        host="127.0.0.1",
        port=5433,
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
    )


def run_command(command, description):
    """Run a project command and stop if it fails."""
    print(f"\n{'=' * 60}")
    print(description)
    print("=" * 60)

    subprocess.run(
        command,
        cwd=ROOT_DIR,
        check=True,
    )


def run_sql(filename):
    """Execute one SQL transformation file."""
    filepath = TRANSFORM_DIR / filename

    print(f"\nRunning SQL: {filename}")

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(filepath.read_text(encoding="utf-8"))


def validate_results():
    """Check the main Customer360 output record counts."""
    print(f"\n{'=' * 60}")
    print("Validating Customer360 results")
    print("=" * 60)

    query = """
        SELECT 'source_contacts', COUNT(*)
        FROM public.crm_contacts

        UNION ALL

        SELECT 'clean_contacts', COUNT(*)
        FROM clean.crm_contacts

        UNION ALL

        SELECT 'identity_resolution', COUNT(*)
        FROM analytics.identity_resolution

        UNION ALL

        SELECT 'resolved_orders', COUNT(*)
        FROM analytics.resolved_orders

        UNION ALL

        SELECT 'customer_360', COUNT(*)
        FROM analytics.customer_360

        UNION ALL

        SELECT 'customer_segments', COUNT(*)
        FROM analytics.customer_segments_with_web_activity
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()

    for name, count in results:
        print(f"{name}: {count:,}")

    expected = {
        "source_contacts": 12292,
        "clean_contacts": 12292,
        "identity_resolution": 8571,
        "resolved_orders": 4009,
        "customer_360": 12292,
        "customer_segments": 12292,
    }

    actual = dict(results)
    failures = []

    for name, expected_count in expected.items():
        if actual.get(name) != expected_count:
            failures.append(
                f"{name}: expected {expected_count:,}, "
                f"got {actual.get(name)}"
            )

    if failures:
        print("\nValidation failed:")

        for failure in failures:
            print(f"- {failure}")

        raise RuntimeError("Customer360 validation failed.")

    print("\nAll record-count validation checks passed.")


def run_data_quality_checks():
    """Run data quality checks and stop if any check fails."""
    print(f"\n{'=' * 60}")
    print("Running data quality checks")
    print("=" * 60)

    filepath = TRANSFORM_DIR / "10_data_quality_checks.sql"

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(filepath.read_text(encoding="utf-8"))
            results = cursor.fetchall()

    failures = []

    for name, count in results:
        status = "PASS" if count == 0 else "FAIL"
        print(f"{status}: {name} = {count}")

        if count != 0:
            failures.append(f"{name}: {count} issue(s)")

    if failures:
        print("\nData quality checks failed:")

        for failure in failures:
            print(f"- {failure}")

        raise RuntimeError("Customer360 data quality validation failed.")

    print("\nAll data quality checks passed.")


def main():
    """Run the complete Customer360 data pipeline."""
    print("Starting Customer360 data pipeline")

    # Step 1: Load the synthetic business datasets.
    run_command(
        [
            sys.executable,
            "-m",
            "customer360.ingestion.load_raw_data",
        ],
        "Step 1: Load raw business data",
    )

    # Step 2: Clean the source tables.
    run_sql("01_cleaned_tables.sql")

    # Step 3: Build verified customer identity mappings.
    run_sql("02_identity_resolution.sql")

    # Step 4: Resolve orders before building Customer360.
    run_sql("04_resolved_orders.sql")

    # Step 5: Build the main customer profiles.
    run_sql("03_customer_360.sql")

    # Step 6: Create the base customer segmentation view.
    run_sql("05_customer_segments.sql")

    # Step 7: Ensure the web activity destination table exists.
    run_sql("07_web_activity.sql")

    # Step 8: Create the combined customer/web activity view.
    run_sql("08_customer_360_web_activity.sql")

    # Step 9: Create the final segmentation view.
    run_sql("09_customer_segments_with_web_activity.sql")

    # Step 10: Validate expected record counts.
    validate_results()

    # Step 11: Run data quality checks.
    run_data_quality_checks()

    print("\nCustomer360 pipeline completed successfully.")


if __name__ == "__main__":
    main()