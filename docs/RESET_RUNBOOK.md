# Health Dataset Full Reset Runbook

Use this runbook when a Health dataset is materially wrong and rebuilding it from the source of truth is faster and safer than targeted repair. Typical examples are incorrect dashboard data, a small dataset that can be reloaded quickly, or a broken current-state/checkpoint condition where a clean restart is the lowest-risk recovery path.

Full reset is deliberately separate from repair/replay.

## Who can run it

Use `AR_HEALTH_RECOVERY`.

This role is intended for Senior Data Engineer+ operators. There is no mandatory multi-person approval chain in the platform implementation. Health Admin inherits the recovery capability, so recovery does not depend on one specific person being available.

The recovery role can use the Health transform warehouse, read the Health domain, truncate Health tables, and call the Health reset lifecycle procedures. It does not receive direct DML on shared `PLATFORM_CONTROL` base tables and does not grant cross-domain recovery access.

## Current supported reset

Dataset:

```text
patient
```

Explicit reconstructable relations:

```text
<ENV>_HEALTH.BRONZE.PATIENT
<ENV>_HEALTH.SILVER_STAGING.PATIENT
<ENV>_HEALTH.SILVER_INTERMEDIATE.PATIENT
<ENV>_HEALTH.SILVER_CANONICAL.PATIENT
<ENV>_HEALTH.GOLD_MARTS.PATIENT
```

`GOLD_SEMANTIC` is not blindly truncated by the generic helper. Add or change reset objects explicitly in `dbt/macros/reset_contract.sql` when the domain implementation changes.

## Before reset

1. Confirm `patient` is reconstructable from its source and that a full reload is the intended recovery action.
2. Record a short incident/recovery reason.
3. Confirm no current `patient` pipeline run is still `RUNNING`. The platform will reject reset start if one exists.
4. Use a new globally unique `reset_id`, for example `health-patient-20260907-001`.
5. Use the deployed/current project Git SHA as `git_sha` when available.

Do not edit shared control tables to stop scheduling. Once reset start succeeds the lifecycle becomes `RESETTING`, and normal dataset pipeline starts/checkpoint writes are blocked by the platform until reset completion.

## Connection context

Use the approved Snowflake account/authentication values for the target environment and set the dbt target context normally used by this repository. The important recovery-specific values are:

```text
ESF_ENVIRONMENT=<dev|uat|prod>
DBT_ROLE=AR_HEALTH_RECOVERY
DBT_DATABASE=<DEV_HEALTH|UAT_HEALTH|PROD_HEALTH>
DBT_WAREHOUSE=<approved Health transform warehouse for that environment>
```

Do not hard-code credentials in the repository or command history.

Install the pinned package revision before running the operation if dependencies are not already installed:

```bash
dbt deps --project-dir dbt --profiles-dir dbt
```

## Execute full reset

From the repository root:

```bash
dbt run-operation health_patient_full_reset \
  --args '{
    "reset_id": "health-patient-20260907-001",
    "reason": "patient-derived dashboard data incorrect; clean reload selected",
    "git_sha": "<project-git-sha>"
  }' \
  --project-dir dbt \
  --profiles-dir dbt
```

The operation performs this sequence:

```text
HEALTH_DATASET_RESET_START
  -> lifecycle = RESETTING
  -> truncate the explicit patient reset relations
  -> HEALTH_DATASET_RESET_COMPLETE
  -> generation N + 1
  -> lifecycle = READY_FOR_INITIAL_LOAD
```

Old checkpoint/bootstrap/run/check-result records remain on the old generation for audit. The new generation has no previous checkpoint/bootstrap state.

## If the reset fails midway

If one of the truncates fails, `RESET_COMPLETE` is not called and the dataset remains `RESETTING`.

Fix the underlying object/privilege/transient problem and rerun the same command with the **same `reset_id`**. The same reset ID is retry-safe only while its status is `RESETTING`.

Once a reset reaches `READY_FOR_RELOAD` or `COMPLETED`, reusing that reset ID fails closed before any truncate. Never reuse an old completed reset ID for a later incident; create a new reset ID.

## Verify reset state

Using `AR_HEALTH_RECOVERY`, inspect only the Health-scoped control views:

```sql
select *
from PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_LIFECYCLE
where dataset_id = 'patient';

select *
from PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_RESET
where dataset_id = 'patient'
order by requested_at desc;
```

After cleanup completes, expect the current generation to be incremented and lifecycle state to be:

```text
READY_FOR_INITIAL_LOAD
```

The reset record should be `READY_FOR_RELOAD` until the fresh main pipeline succeeds.

## Reload

Run the normal `patient` main pipeline using the normal deploy/runtime path. Do not manually write a checkpoint or control-table row to make the dataset look healthy.

The successful new-generation pipeline/checkpoint path automatically moves lifecycle state back to:

```text
ACTIVE
```

and finalizes the reset record as:

```text
COMPLETED
```

Then validate the normal reconciliation/DQ/dashboard checks before closing the incident.

## What not to do

Do not use full reset for every bad row. Prefer repair/replay when the problem is bounded and the correct recovery can be proven without rebuilding the dataset.

Do not delete old `PLATFORM_CONTROL` generation history. Generation rollover is what makes reset auditable and prevents stale checkpoints from being reused.

Do not add arbitrary caller-provided table names to the reset command. The allowed cleanup set belongs in the domain repository's explicit `dbt/macros/reset_contract.sql`.
