# Current Context

Concise handoff for a new conversation.

## Architectural rule

Health has a **framework-independent portable core**. Source contracts and synthetic data generation must work on any Snowflake platform without the enterprise framework, `PLATFORM_CONTROL`, Terraform, WIF, enterprise RBAC, or enterprise database/warehouse naming.

```text
portable Health core
  contracts/
  config/
  standalone/
  domain docs
        ↑
optional enterprise adapter
  dbt/
  enterprise workflows
        ↑
enterprise framework/platform
```

See `docs/PORTABILITY.md` and `standalone/README.md`.

## Active stack

```text
PR #1 domain operational proof
PR #2 Medallion/config/one-click enterprise deploy
PR #3 generation-aware full reset
PR #4 framework-free portable synthetic data + stateful source simulator
```

PR #4 is stacked on PR #3 while the lower stack remains open.

## Portable demo — PR #4

Bulk deterministic source data:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_patient.sql
standalone/sql/90_validate.sql
```

Bulk objects:

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` matches the formal RAW contract. `PATIENT_DEMO_PROFILE` is explicitly synthetic-only demo data and does not silently expand the production contract. No row represents a real person.

Stateful incremental source simulator:

```text
standalone/sql/30_incremental_patient_simulator.sql

DEMO_HEALTH.PATIENT_SIM_CDC
DEMO_HEALTH.PATIENT_SIM_CURRENT
DEMO_HEALTH.PATIENT_SIM_STATE
DEMO_HEALTH.RESET_PATIENT_SIMULATOR()
DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR()
```

The simulator uses native Snowflake Scripting (`LANGUAGE SQL`), not Python. `RESET` returns `current_batch` to `-1`. The first `ADVANCE` emits deterministic insert records for 1000 synthetic patient IDs. Later calls emit deterministic update records for a bounded subset; later batches also emit a small number of delete tombstones. Event timestamps and source sequences are deterministic so reset-and-replay is reproducible.

The simulator models **source CDC only**. Target history behavior remains the responsibility of the consuming pipeline. The current enterprise adapter still intentionally uses `scd1_merge` for `patient`; another platform can consume the same simulator with SCD2 or another strategy if its domain model requires it.

The standalone SQL creates no database/warehouse/role and contains no enterprise framework or control-plane dependency. Bulk and incremental simulator objects are separate and can coexist.

Verified simulator source/static head:

```text
244399005b72df51a71f8465e0094927a220a489
Standalone SQL CI #7: SUCCESS
PR Workspace #24: FAILURE at Load approved Snowflake environment configuration
```

This `CURRENT_CONTEXT.md` update is documentation-only after that verified source head. The PR Workspace failure belongs to the optional enterprise adapter and occurs before checkout/Snowflake execution.

## Optional enterprise adapter

Current reset-aware framework pin used only by the enterprise dbt/workflow path:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

Enterprise stable databases use `<ENV>_HEALTH` plus Medallion schemas. Those names are not portable-core requirements.

## Reference dataset

`patient` remains a full-change CDC reference dataset and intentionally uses `scd1_merge` in the enterprise adapter because the formal RAW contract currently lacks real business attributes suitable for SCD2 tracking.

The portable bulk generator and stateful simulator provide CDC evidence plus a separately labeled synthetic profile for dashboard experiments without claiming a live EHR source.

## Full reset enterprise adapter

```text
role: AR_HEALTH_RECOVERY
operation: health_patient_full_reset
ACTIVE generation N
 -> RESETTING
 -> explicit Bronze/Silver/Gold cleanup
 -> generation N+1 / READY_FOR_INITIAL_LOAD
 -> normal pipeline success
 -> ACTIVE
```

Same reset ID retries only while `RESETTING`; ready/completed IDs fail before cleanup. See `docs/RESET_RUNBOOK.md`.

Verified lower stack:

```text
Framework reset
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS

Platform reset
c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
Terraform CI #167: SUCCESS
Platform Control SQL CI #37: SUCCESS

Health reset
d33f92a928e3c9ca553a843c2c52c4952d86a13b
dbt Static CI #34: SUCCESS
```

## Live boundaries

Portable live acceptance:

```text
plain Snowflake database
no framework package
no PLATFORM_CONTROL
no enterprise roles/naming
 -> execute standalone setup + simulator SQL
 -> RESET simulator
 -> ADVANCE initial batch
 -> inspect CDC/current state
 -> ADVANCE multiple change batches
 -> verify deterministic I/U/D evolution
 -> optionally run any consuming pipeline between ADVANCE calls
```

Current Snowflake Scripting variable-binding and `SQLROWCOUNT` placement have been checked against Snowflake documentation, but static CI is not a live Snowflake compiler/runtime proof.

Enterprise live acceptance separately requires real DEV Snowflake/WIF for grants, control plane, reset generation rollover and pipelines.
