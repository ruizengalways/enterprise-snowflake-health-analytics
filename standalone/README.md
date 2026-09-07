# Standalone synthetic data

This directory is the portable entry point for this repository.

It uses **Snowflake SQL only**. It does not require dbt, the enterprise data framework, `PLATFORM_CONTROL`, Terraform, a particular role hierarchy, warehouse name, or database naming convention.

## Prerequisites

Connect to any Snowflake account, select any database and warehouse, and use a role that can create a schema plus tables/views in that database.

The scripts never create or switch databases, roles, or warehouses.

## Run order

Execute these files in order using Snowsight, SnowSQL, Snowflake CLI, JDBC/ODBC, or any SQL client:

```text
00_setup.sql
10_generate_patient.sql
90_validate.sql
```

The scripts create only:

```text
DEMO_HEALTH
```

Re-running the generation script deterministically replaces the demo tables/views.

## Generated objects

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` matches the current repository RAW contract for `patient` and contains insert/update/tombstone-delete source evidence. `PATIENT_DEMO_PROFILE` is additional synthetic-only descriptive data for demos and dashboard experiments; it is deliberately not presented as part of the current RAW contract.

No row represents a real person or external source record.

## Cleanup

Run:

```text
99_cleanup.sql
```

This drops only `DEMO_HEALTH` in the currently selected database.

## Enterprise integration

The repository may also contain optional dbt/platform integration for the enterprise Snowflake platform. That integration is not required to generate or inspect this demo data. A consumer on another Snowflake platform can ignore it completely.
