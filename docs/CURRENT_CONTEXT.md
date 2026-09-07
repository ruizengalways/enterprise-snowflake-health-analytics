# Current Context

Concise handoff for a new conversation.

## Active stack

```text
PR #1  feature/domain-operational-contract
  second-domain proof of domain-scoped operational control

PR #2  feature/medallion-one-click-deploy
  Medallion naming, immutable config audit and simplified stable deployment

PR #3  feature/dataset-reset-generation
  Senior+ full reset + generation-aware recovery for patient
```

PR #3 is intentionally stacked on PR #2. Retarget stacked PRs after lower dependencies merge.

## Framework pin

Current reset-aware immutable framework pin used by this branch:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

It includes Medallion workspace/target naming, explicit `scd1_merge`, metadata-driven SCD2/bootstrap contracts, deterministic dataset config snapshots, stable deployment helpers and bounded full-reset execution helpers.

## Domain database contract

```text
<ENV>_HEALTH
  BRONZE
  SILVER_STAGING
  SILVER_INTERMEDIATE
  SILVER_CANONICAL
  GOLD_MARTS
  GOLD_SEMANTIC
  DQ
```

Ordinary new sources share `BRONZE`; adding a source should not require a Terraform-created database/schema by default.

## Control plane

Runtime state:

```text
PLATFORM_CONTROL.OPERATIONS.HEALTH_*
```

Deployment config audit:

```text
PLATFORM_CONTROL.CONFIG.HEALTH_DATASET_CONFIG_SNAPSHOT
PLATFORM_CONTROL.CONFIG.HEALTH_REGISTER_DATASET_CONFIG_SNAPSHOT
```

Reset/generation surface:

```text
PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_LIFECYCLE
PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_RESET
PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_RESET_START
PLATFORM_CONTROL.OPERATIONS.HEALTH_DATASET_RESET_COMPLETE
```

Git is configuration truth. Snowflake CONFIG is immutable deployment audit/readback state; OPERATIONS contains mutable runtime/recovery state.

## Reference dataset

`patient` is the current Health reference dataset. `ehr_mssql` is a reference source identity only; no live SQL Server source connection is claimed.

The RAW contract declares full-change CDC evidence but does not declare real business attributes that would be meaningful SCD2 tracked columns. Therefore `patient` remains intentionally configured as `scd1_merge` current-state behavior. Transport `vehicle_status` remains the standard SCD2 consumer.

## Full reset

Operator role:

```text
AR_HEALTH_RECOVERY
```

Intended for Senior Data Engineer+ incident recovery. No mandatory multi-person approval chain is implemented. Health Admin inherits the recovery capability.

Executable operation:

```text
health_patient_full_reset
```

Current explicit reset plan:

```text
<ENV>_HEALTH.BRONZE.PATIENT
<ENV>_HEALTH.SILVER_STAGING.PATIENT
<ENV>_HEALTH.SILVER_INTERMEDIATE.PATIENT
<ENV>_HEALTH.SILVER_CANONICAL.PATIENT
<ENV>_HEALTH.GOLD_MARTS.PATIENT
```

Lifecycle:

```text
ACTIVE generation N
  -> RESETTING
  -> explicit cleanup
  -> generation N+1 / READY_FOR_INITIAL_LOAD
  -> normal patient pipeline succeeds
  -> ACTIVE
```

Old runtime generation records remain auditable. A failed cleanup remains `RESETTING` and can retry with the same reset ID. A reset ID that already reached `READY_FOR_RELOAD` or `COMPLETED` is rejected before cleanup; a later incident must use a new reset ID.

Operational instructions: `docs/RESET_RUNBOOK.md`.

## Deployment UX

After the lower stack is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The wrapper passes the selected workflow revision SHA to the reusable framework workflow, which requires that SHA to be reachable from current `main` and verifies the exact framework pin.

After successful `dbt build`, validated dataset config snapshots are registered through Health-scoped owner-rights procedures. A failed build is not recorded as a successful deployed configuration.

## Static proof

Latest reset-contract source/static proof:

```text
d33f92a928e3c9ca553a843c2c52c4952d86a13b
dbt Static CI #34: SUCCESS
PR Workspace #15: FAILURE at Load approved Snowflake environment configuration
```

The current branch also contains documentation-only commits after that source/static head. The Workspace failure occurs before Snowflake execution; approved `ci` Snowflake environment/WIF configuration is still unavailable.

Static CI proves reset SQL rendering, explicit relation scope, Health domain/control isolation, Medallion target/profile compatibility and config snapshot boundaries.

Live DEV remains required for real authentication, recovery role/table privileges, generation rollover, completed reset-ID rejection, cross-domain denial, source behavior, transaction/concurrency semantics, retries/recovery and actual reload execution.

## Cross-repository dependencies

```text
framework PR #5
  reset-aware pin 8afe208bd911a59b9334add78a53878ffea93087

platform-infra PR #3
  generation-aware reset control
  verified head c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
  Terraform CI #167: SUCCESS
  Platform Control SQL CI #37: SUCCESS
```

Lower platform/framework PRs remain dependencies for runtime/bootstrap, Medallion and CONFIG control.

Do not describe this repository as live-deployed until platform DEV bootstrap and WIF are complete.
