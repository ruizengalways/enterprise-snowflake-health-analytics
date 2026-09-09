# Health Dataset Processing Reset Runbook

Use this runbook when `patient` downstream current-state processing is materially wrong and rebuilding Silver from already-landed Bronze evidence is safer than targeted repair.

This is a **processing full reset**, not an ingestion/source reset. Source -> Bronze is ingestion-owned, so this operation deliberately preserves Bronze evidence.

## Who can run it

Use `AR_HEALTH_RECOVERY`. Health Admin inherits the recovery capability. The recovery role uses the Health transform warehouse and domain-scoped reset APIs; it does not receive direct DML on shared `PLATFORM_CONTROL` base tables or cross-domain recovery access.

## Current supported reset

Dataset:

```text
patient
```

The explicit v2 cleanup set is:

```text
<ENV>_HEALTH.SILVER_CANONICAL.PATIENT
```

The reset intentionally does **not** truncate:

```text
BRONZE.PATIENT                 ingestion-owned landed evidence
SILVER_STAGING.STG_PATIENT     view
```

The normal SCD1 processing path reconstructs the canonical current-state table from preserved Bronze evidence. If Bronze itself is corrupt, stop here and coordinate a separate ingestion-owned recovery/reland procedure before running the processing reset.

## Safety guards

`dbt/macros/reset_contract.sql` fails closed unless all of these are true:

- `ESF_ENVIRONMENT` is exactly `dev`, `uat` or `prod`;
- `target.database` is the matching `DEV_HEALTH`, `UAT_HEALTH` or `PROD_HEALTH` database;
- `ESF_SCHEMA_PREFIX` is empty, so the operation cannot be invoked from a prefixed PR/personal workspace;
- cleanup relations come from the compile-time domain list, never caller-supplied table names.

## Before reset

1. Confirm Bronze contains the source evidence required to rebuild `patient` current state.
2. Confirm a processing full reset is preferable to bounded repair/replay.
3. Record a short incident/recovery reason.
4. Confirm no current-generation `patient` pipeline run is still `RUNNING`; the platform rejects reset start otherwise.
5. Create a globally unique `reset_id`, for example `health-patient-20260909-001`.
6. Use the deployed/current project Git SHA as `git_sha` when available.

Do not edit shared control tables to stop scheduling. Once reset start succeeds, lifecycle becomes `RESETTING` and normal dataset pipeline starts/checkpoint writes are blocked until reset completion.

## Connection context

Use the approved Snowflake authentication for the target environment and set:

```text
ESF_ENVIRONMENT=<dev|uat|prod>
ESF_SCHEMA_PREFIX=
DBT_ROLE=AR_HEALTH_RECOVERY
DBT_DATABASE=<DEV_HEALTH|UAT_HEALTH|PROD_HEALTH>
DBT_WAREHOUSE=<approved Health transform warehouse>
```

Never hard-code credentials in the repository or command history. Install the pinned package revision first if needed:

```bash
dbt deps --project-dir dbt --profiles-dir dbt
```

## Execute processing reset

From the repository root:

```bash
dbt run-operation health_patient_full_reset \
  --args '{
    "reset_id": "health-patient-20260909-001",
    "reason": "patient current state incorrect; rebuild from retained Bronze evidence",
    "git_sha": "<project-git-sha>"
  }' \
  --project-dir dbt \
  --profiles-dir dbt
```

The operation performs:

```text
HEALTH_DATASET_RESET_START
  -> lifecycle = RESETTING
  -> truncate SILVER_CANONICAL.PATIENT
  -> HEALTH_DATASET_RESET_COMPLETE
  -> generation N + 1
  -> lifecycle = READY_FOR_INITIAL_LOAD
```

Old checkpoint/bootstrap/run/check-result rows remain attached to the old generation for audit. The new generation exposes no old checkpoint/bootstrap state.

## If reset fails midway

If the truncate fails, `RESET_COMPLETE` is not called and lifecycle remains `RESETTING`. Fix the object/privilege/transient problem and retry with the **same `reset_id`**. A reset ID is retry-safe only while that reset remains `RESETTING`.

Never reuse a completed/ready reset ID for a later incident.

## Verify control state

Using `AR_HEALTH_RECOVERY`:

```sql
select *
from PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_LIFECYCLE
where dataset_id = 'patient';

select *
from PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_RESET
where dataset_id = 'patient'
order by requested_at desc;
```

After cleanup, expect the new generation lifecycle to be `READY_FOR_INITIAL_LOAD` and the reset record to remain ready for reload until the normal pipeline succeeds.

## Reload

Run the normal `patient` processing pipeline. Because Bronze was preserved, the SCD1 materialization rebuilds canonical current state from landed evidence. Do not manually manufacture a checkpoint.

A successful new-generation pipeline/checkpoint path returns lifecycle to `ACTIVE` and finalizes the reset as `COMPLETED`. Then validate reconciliation/DQ and downstream consumers.

## What not to do

- Do not use processing full reset for every bad row; prefer bounded repair/replay where correctness can be proven.
- Do not delete old `PLATFORM_CONTROL` generation history.
- Do not add arbitrary caller-provided relation names to the reset operation.
- Do not use this operation to repair corrupt/missing Bronze evidence; that belongs to the ingestion recovery path.
