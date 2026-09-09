# Health Analytics

Health is a domain project. External ingestion lands source-faithful Bronze data; the Framework starts with downstream Snowflake processing.

## Patient path

- `contracts/raw/patient.yml` describes the source grain, CDC operation/sequence and tombstone semantics.
- `config/datasets/patient.yml` says only how downstream state is maintained: `load.strategy: scd1`, table materialization, dbt runtime, logical `transform` workload.
- `dbt/models/silver_staging/stg_patient.sql` is readable landed-data staging SQL.
- `dbt/models/silver_canonical/patient.sql` expresses the domain/current-row selection explicitly. The Framework SCD1 materialization applies keyed upserts and tombstone deletes.

Patient remains **SCD1**. It is not changed to SCD2 merely to demonstrate a Framework feature.

```text
BRONZE.patient
  -> SILVER_STAGING.stg_patient
  -> SILVER_CANONICAL.patient   (SCD1 current state)
```

The portable `standalone/` simulator remains independent of the Framework, PLATFORM_CONTROL, Terraform and enterprise WIF.

Static CI validates metadata and parses dbt offline. Live Snowflake SCD1/delete/reset/deployment acceptance remains a separate WIF gate and is not claimed by this repository until it actually runs.
