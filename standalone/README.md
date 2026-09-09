# Standalone synthetic data

This directory is the portable entry point for this repository.

It uses **Snowflake SQL only**. It does not require dbt, the enterprise data framework, `PLATFORM_CONTROL`, Terraform, a particular role hierarchy, warehouse name, or database naming convention.

## Prerequisites

Connect to any Snowflake account, select any database and warehouse, and use a role that can create a schema plus tables/views/procedures in that database.

The scripts never create or switch databases, roles, or warehouses.

## Bulk demo data

Execute these files in order using Snowsight, SnowSQL, Snowflake CLI, JDBC/ODBC, or any SQL client:

```text
00_setup.sql
10_generate_patient.sql
90_validate.sql
```

This deterministic path creates:

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` matches the current repository RAW contract for `patient` and contains insert/update/tombstone-delete source evidence. `PATIENT_DEMO_PROFILE` is additional synthetic-only descriptive data for demos and dashboard experiments; it is deliberately not presented as part of the current RAW contract.

## Stateful incremental simulator

Run once to install the simulator:

```text
30_incremental_patient_simulator.sql
```

It creates independent simulator objects:

```text
DEMO_HEALTH.PATIENT_SIM_CDC
DEMO_HEALTH.PATIENT_SIM_CURRENT
DEMO_HEALTH.PATIENT_SIM_STATE
DEMO_HEALTH.RESET_PATIENT_SIMULATOR()
DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR()
```

The procedures use Snowflake SQL Scripting (`LANGUAGE SQL`), not Python.

Typical incremental test cycle:

```sql
CALL DEMO_HEALTH.RESET_PATIENT_SIMULATOR();

CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
-- initial I records: run your pipeline

CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
-- deterministic U records: run your pipeline again

CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
-- more changes

CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR();
-- later batches also contain a small number of D tombstones
```

Each call advances `current_batch`. Event timestamps and source sequences are deterministic, so the same reset-and-advance sequence is reproducible. The simulator emits source CDC; target history behavior remains the responsibility of the consuming pipeline.

The bulk and incremental paths use different tables, so they can coexist.

## Schema and cleanup

All standalone objects live only in:

```text
DEMO_HEALTH
```

No row represents a real person or external source record.

Run:

```text
99_cleanup.sql
```

This drops only `DEMO_HEALTH` in the currently selected database.

## Enterprise integration

The repository may also contain optional dbt/platform integration for the enterprise Snowflake platform. That integration is not required to generate or inspect this demo data. A consumer on another Snowflake platform can ignore it completely.
