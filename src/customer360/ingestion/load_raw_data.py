import csv
import json
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


# Find the project root directory
ROOT_DIR = Path(__file__).resolve().parents[3]

# Load environment variables from .env
load_dotenv(ROOT_DIR / ".env")

# Folder containing source data
RAW_DIR = ROOT_DIR / "data" / "raw"


def get_connection():
    """Connect to our PostgreSQL database."""
    return psycopg.connect(
        host="localhost",
        port=5433,
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
    )


def clean_value(value):
    """Convert empty CSV values into SQL NULL."""
    if value is None or value.strip() == "":
        return None

    return value.strip()


def load_csv(connection, filename, table, columns):
    """Load a CSV file into its PostgreSQL table."""
    filepath = RAW_DIR / filename
    count = 0

    with open(filepath, "r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)

        with connection.cursor() as cur:
            for row in reader:
                values = [clean_value(row.get(col)) for col in columns]

                placeholders = ", ".join(["%s"] * len(columns))
                column_names = ", ".join(columns)

                query = (
                    f"INSERT INTO {table} ({column_names}) "
                    f"VALUES ({placeholders}) "
                    f"ON CONFLICT DO NOTHING"
                )

                cur.execute(query, values)
                count += 1

    connection.commit()
    print(f"{filename}: processed {count} rows")


def load_jsonl(connection, filename, table, columns):
    """Load a JSON Lines file into its PostgreSQL table."""
    filepath = RAW_DIR / filename
    count = 0

    with open(filepath, "r", encoding="utf-8") as file:
        with connection.cursor() as cur:
            for line in file:
                if not line.strip():
                    continue

                row = json.loads(line)

                values = []
                for col in columns:
                    value = row.get(col)

                    if isinstance(value, bool):
                        values.append(value)
                    elif value is None:
                        values.append(None)
                    else:
                        values.append(str(value).strip() or None)

                placeholders = ", ".join(["%s"] * len(columns))
                column_names = ", ".join(columns)

                query = (
                    f"INSERT INTO {table} ({column_names}) "
                    f"VALUES ({placeholders}) "
                    f"ON CONFLICT DO NOTHING"
                )

                cur.execute(query, values)
                count += 1

    connection.commit()
    print(f"{filename}: processed {count} rows")


def main():
    """Load all seven source files into PostgreSQL."""

    connection = get_connection()

    try:
        print("Connected to PostgreSQL.")
        print("Starting data ingestion...\n")

        # Load parent tables before tables that reference them.
        load_csv(
            connection,
            "crm_contacts.csv",
            "crm_contacts",
            [
                "contact_id",
                "web_user_id",
                "first_name",
                "last_name",
                "email",
                "phone",
                "loyalty_tier",
                "created_at",
                "updated_at",
            ],
        )

        load_csv(
            connection,
            "orders.csv",
            "orders",
            [
                "order_id",
                "contact_id",
                "web_user_id",
                "ordered_at",
                "order_status",
                "gross_amount",
                "currency_code",
                "source_purchase_items",
                "updated_at",
            ],
        )

        load_csv(
            connection,
            "payments.csv",
            "payments",
            [
                "payment_id",
                "order_id",
                "payment_status",
                "payment_amount",
                "currency_code",
                "updated_at",
            ],
        )

        load_jsonl(
            connection,
            "identity_links.jsonl",
            "identity_links",
            [
                "link_id",
                "contact_id",
                "web_user_id",
                "user_session",
                "verification_method",
                "verified",
                "linked_at",
            ],
        )

        load_jsonl(
            connection,
            "support_tickets.jsonl",
            "support_tickets",
            [
                "ticket_id",
                "email",
                "contact_id",
                "topic",
                "status",
                "updated_at",
            ],
        )

        load_csv(
            connection,
            "campaign_events.csv",
            "campaign_events",
            [
                "campaign_event_id",
                "contact_id",
                "event_type",
                "event_time",
                "campaign_id",
            ],
        )

        load_csv(
            connection,
            "consent_changes.csv",
            "consent_changes",
            [
                "consent_id",
                "contact_id",
                "channel",
                "consent_status",
                "updated_at",
            ],
        )

        print("\nData ingestion finished.")

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


if __name__ == "__main__":
    main()