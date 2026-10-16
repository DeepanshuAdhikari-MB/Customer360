from unittest.mock import MagicMock, patch

import pytest

from customer360.pipeline.run_pipeline import validate_results


def create_mock_connection(results):
    """Create a fake PostgreSQL connection for testing."""
    connection = MagicMock()
    cursor = MagicMock()

    connection.__enter__.return_value = connection
    connection.cursor.return_value.__enter__.return_value = cursor
    cursor.fetchall.return_value = results

    return connection


@patch("customer360.pipeline.run_pipeline.get_connection")
def test_validate_results_success(mock_get_connection):
    """Validation should pass when all counts match."""
    results = [
        ("source_contacts", 12292),
        ("clean_contacts", 12292),
        ("identity_resolution", 8571),
        ("resolved_orders", 4009),
        ("customer_360", 12292),
        ("customer_segments", 12292),
    ]

    mock_get_connection.return_value = create_mock_connection(results)

    validate_results()


@patch("customer360.pipeline.run_pipeline.get_connection")
def test_validate_results_failure(mock_get_connection):
    """Validation should fail when a count is incorrect."""
    results = [
        ("source_contacts", 100),
        ("clean_contacts", 12292),
        ("identity_resolution", 8571),
        ("resolved_orders", 4009),
        ("customer_360", 12292),
        ("customer_segments", 12292),
    ]

    mock_get_connection.return_value = create_mock_connection(results)

    with pytest.raises(RuntimeError, match="Customer360 validation failed"):
        validate_results()
from customer360.pipeline.run_pipeline import run_data_quality_checks


@patch("customer360.pipeline.run_pipeline.get_connection")
def test_data_quality_checks_success(mock_get_connection):
    """Data quality checks should pass when no issues are found."""
    results = [
        ("duplicate_source_customer_ids", 0),
        ("missing_source_customer_ids", 0),
        ("duplicate_identity_mappings", 0),
        ("negative_order_amounts", 0),
        ("opted_out_but_marketing_eligible", 0),
    ]

    mock_get_connection.return_value = create_mock_connection(results)

    run_data_quality_checks()


@patch("customer360.pipeline.run_pipeline.get_connection")
def test_data_quality_checks_failure(mock_get_connection):
    """Data quality checks should fail when an issue is found."""
    results = [
        ("duplicate_source_customer_ids", 1),
        ("missing_source_customer_ids", 0),
        ("duplicate_identity_mappings", 0),
        ("negative_order_amounts", 0),
        ("opted_out_but_marketing_eligible", 0),
    ]

    mock_get_connection.return_value = create_mock_connection(results)

    with pytest.raises(
        RuntimeError,
        match="Customer360 data quality validation failed",
    ):
        run_data_quality_checks()
