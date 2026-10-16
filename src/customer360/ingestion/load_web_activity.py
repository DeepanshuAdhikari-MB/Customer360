

import os
from pathlib import Path

import clickhouse_connect
import psycopg
from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[3]

load_dotenv(ROOT_DIR / ".env")


def get_clickhouse_client():
    return clickhouse_connect.get_client(
        host="127.0.0.1",
        port=8123,
        username=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
        database=os.getenv("CLICKHOUSE_DB", "customer360"),
    )


def get_postgres_connection():
    return psycopg.connect(
        host="127.0.0.1",
        port=5433,
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
    )


def main():
    ch = get_clickhouse_client()
    pg = get_postgres_connection()

    try:
        print("Connected to ClickHouse and PostgreSQL.")

        query = """
            SELECT
                toString(user_id) AS web_user_id,

                countIf(event_type = 'view') AS total_views,
                countIf(event_type = 'cart') AS total_cart_events,
                countIf(event_type = 'purchase') AS total_purchase_events,

                min(event_time) AS first_event_at,
                max(event_time) AS last_event_at

            FROM customer360.web_events FINAL
            GROUP BY user_id
            ORDER BY user_id
        """

        result = ch.query(query)
        rows = result.result_rows

        print(f"Aggregated users: {len(rows):,}")

        if not rows:
            print("No web activity found.")
            return

        batch_size = 1000

        insert_sql = """
            INSERT INTO analytics.web_activity (
                web_user_id,
                total_views,
                total_cart_events,
                total_purchase_events,
                first_event_at,
                last_event_at,
                updated_at
            )
            VALUES (
                %(web_user_id)s,
                %(total_views)s,
                %(total_cart_events)s,
                %(total_purchase_events)s,
                %(first_event_at)s,
                %(last_event_at)s,
                CURRENT_TIMESTAMP
            )
            ON CONFLICT (web_user_id)
            DO UPDATE SET
                total_views = EXCLUDED.total_views,
                total_cart_events = EXCLUDED.total_cart_events,
                total_purchase_events = EXCLUDED.total_purchase_events,
                first_event_at = EXCLUDED.first_event_at,
                last_event_at = EXCLUDED.last_event_at,
                updated_at = CURRENT_TIMESTAMP
        """

        with pg.cursor() as cur:
            for start in range(0, len(rows), batch_size):
                batch = rows[start:start + batch_size]

                data = [
                    {
                        "web_user_id": row[0],
                        "total_views": row[1],
                        "total_cart_events": row[2],
                        "total_purchase_events": row[3],
                        "first_event_at": row[4],
                        "last_event_at": row[5],
                    }
                    for row in batch
                ]

                cur.executemany(insert_sql, data)
                pg.commit()

                print(
                    f"Loaded {min(start + len(batch), len(rows)):,}"
                    f" / {len(rows):,} users"
                )

        print("Web activity ETL completed successfully.")

    finally:
        pg.close()
        ch.close()


if __name__ == "__main__":
    main()