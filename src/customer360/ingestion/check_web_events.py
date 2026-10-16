import os
from pathlib import Path

import clickhouse_connect
from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[3]

load_dotenv(ROOT_DIR / ".env")


def main():
    client = clickhouse_connect.get_client(
        host="127.0.0.1",
        port=8123,
        username=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
        database=os.getenv("CLICKHOUSE_DB", "customer360"),
    )

    try:
        result = client.query("""
            SELECT
                count() AS total_rows,
                uniqExact(source_row_number) AS unique_rows,
                min(source_row_number) AS first_row,
                max(source_row_number) AS last_row
            FROM customer360.web_events FINAL
        """)

        total, unique, first, last = result.result_rows[0]

        print(f"Total rows: {total:,}")
        print(f"Unique source rows: {unique:,}")
        print(f"First source row: {first:,}")
        print(f"Last source row: {last:,}")

        if (
            total == unique
            and total > 0
            and first == 1
            and total == last
        ):
            print("Validation passed: source rows are contiguous.")
        else:
            print("Validation failed: check for duplicate or missing rows.")

    finally:
        client.close()


if __name__ == "__main__":
    main()