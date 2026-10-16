import argparse
import csv
import io
import json
import os
import zipfile

from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import clickhouse_connect
from dotenv import load_dotenv


ROOT_DIR = Path(__file__).resolve().parents[3]
ZIP_PATH = Path.home() / "Downloads" / "archive(1).zip"
CHECKPOINT_PATH = ROOT_DIR / "data" / "raw" / "web_events_checkpoint.json"

BATCH_SIZE = 10_000
TABLE_NAME = "customer360.web_events"

COLUMNS = [
    "event_time",
    "event_type",
    "product_id",
    "category_id",
    "category_code",
    "brand",
    "price",
    "user_id",
    "user_session",
    "source_row_number",
]

load_dotenv(ROOT_DIR / ".env")


def create_client():
    return clickhouse_connect.get_client(
        host="127.0.0.1",
        port=8123,
        username=os.getenv("CLICKHOUSE_USER"),
        password=os.getenv("CLICKHOUSE_PASSWORD"),
        database=os.getenv("CLICKHOUSE_DB", "customer360"),
    )


def parse_optional_int(value):
    value = value.strip()
    return int(value) if value else None


def parse_optional_decimal(value):
    value = value.strip()
    return Decimal(value) if value else None


def parse_timestamp(value):
    value = value.replace(" UTC", "+00:00")
    return datetime.fromisoformat(value).astimezone(timezone.utc)


def convert_row(row, row_number):
    return [
        parse_timestamp(row["event_time"]),
        row["event_type"].strip(),
        parse_optional_int(row["product_id"]),
        parse_optional_int(row["category_id"]),
        row["category_code"].strip() or None,
        row["brand"].strip() or None,
        parse_optional_decimal(row["price"]),
        int(row["user_id"]),
        row["user_session"].strip() or None,
        row_number,
    ]


def read_checkpoint():
    if not CHECKPOINT_PATH.exists():
        return 0

    with CHECKPOINT_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)

    return int(data["last_completed_row"])


def save_checkpoint(row_number):
    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)

    temporary_path = CHECKPOINT_PATH.with_suffix(".tmp")

    with temporary_path.open("w", encoding="utf-8") as file:
        json.dump({"last_completed_row": row_number}, file)

    temporary_path.replace(CHECKPOINT_PATH)


def get_database_progress(client):
    result = client.query(f"""
        SELECT
            count(),
            uniqExact(source_row_number),
            min(source_row_number),
            max(source_row_number)
        FROM {TABLE_NAME} FINAL
    """)

    total, unique, first, last = result.result_rows[0]

    if total == 0:
        return 0

    if total != unique or first != 1 or total != last:
        raise RuntimeError(
            "ClickHouse data contains duplicate or missing source rows. "
            "Stop and investigate before resuming."
        )

    return int(last)


def insert_batch(client, batch):
    if not batch:
        return

    client.insert(
        TABLE_NAME,
        batch,
        column_names=COLUMNS,
    )


def load_events(limit=None, resume=False):
    client = create_client()
    total_inserted = 0
    batch = []

    try:
        database_row = get_database_progress(client)

        if resume:
            checkpoint_row = read_checkpoint()

            if database_row < checkpoint_row:
                raise RuntimeError(
                    f"Database progress ({database_row}) is behind "
                    f"the checkpoint ({checkpoint_row}). "
                    "Stop and investigate before resuming."
                )

            if database_row > checkpoint_row:
                print(
                    "Recovering checkpoint: "
                    f"{checkpoint_row:,} -> {database_row:,}"
                )
                save_checkpoint(database_row)

            start_after = database_row

        else:
            if database_row != 0:
                raise RuntimeError(
                    f"{TABLE_NAME} already contains data up to source row "
                    f"{database_row:,}. Use --resume to continue, or "
                    "clear the test data before starting a fresh load."
                )

            start_after = 0
            save_checkpoint(0)

        print(f"Starting after source row {start_after:,}")

        with zipfile.ZipFile(ZIP_PATH) as archive:
            with archive.open("2019-Oct.csv") as file:
                text_file = io.TextIOWrapper(
                    file,
                    encoding="utf-8",
                    newline="",
                )

                reader = csv.DictReader(text_file)

                for row_number, row in enumerate(reader, start=1):
                    if row_number <= start_after:
                        continue

                    batch.append(convert_row(row, row_number))

                    # Stop collecting once this run reaches its limit.
                    if limit is not None:
                        if total_inserted + len(batch) >= limit:
                            remaining = limit - total_inserted
                            batch = batch[:remaining]

                            insert_batch(client, batch)

                            total_inserted += len(batch)
                            last_row = batch[-1][-1]

                            save_checkpoint(last_row)

                            print(
                                f"Inserted {total_inserted:,} rows "
                                f"in this run. Source row: {last_row:,}"
                            )

                            batch.clear()
                            break

                    if len(batch) >= BATCH_SIZE:
                        insert_batch(client, batch)

                        total_inserted += len(batch)
                        last_row = batch[-1][-1]

                        save_checkpoint(last_row)

                        print(
                            f"Inserted {total_inserted:,} rows "
                            f"in this run. Source row: {last_row:,}"
                        )

                        batch.clear()

                if batch:
                    insert_batch(client, batch)

                    total_inserted += len(batch)
                    last_row = batch[-1][-1]

                    save_checkpoint(last_row)

                    print(
                        f"Inserted {total_inserted:,} rows "
                        f"in this run. Source row: {last_row:,}"
                    )

        print(f"Finished. Inserted {total_inserted:,} rows in this run.")
        print(f"Last completed source row: {read_checkpoint():,}")

    finally:
        client.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Load October website events into ClickHouse."
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Maximum rows to insert in this run.",
    )

    parser.add_argument(
        "--resume",
        action="store_true",
        help="Resume from verified database progress.",
    )

    args = parser.parse_args()

    if args.limit is not None and args.limit <= 0:
        parser.error("--limit must be greater than zero")

    load_events(limit=args.limit, resume=args.resume)