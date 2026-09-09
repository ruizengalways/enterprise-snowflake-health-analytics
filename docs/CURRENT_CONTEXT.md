# Current Context — Health v2

Updated: 2026-09-09

## Canonical state

Health Hybrid Framework v2 is merged to `main`. The v2 baseline merge is:

```text
22727ed713c55963824892c61f4f6f5c7141a995
```

The enterprise adapter pins the merged Framework v2 baseline:

```text
7d3498f8b5ef48d868ea44aade62cf13e50e58f6
Framework v2 CI #193: SUCCESS
```

Health PR #5 is the canonical v2 migration. Earlier stacked PRs #2–#4 are closed as superseded; their old framework pins and combined strategy vocabulary are historical only.

## Architectural rule

Health keeps a **framework-independent portable core**:

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

Source contracts and synthetic data generation must work without Framework, `PLATFORM_CONTROL`, Terraform, enterprise WIF/RBAC or enterprise database/warehouse naming.

## Current reference dataset

`patient` remains a full-change CDC source reference and intentionally uses:

```text
load.strategy: scd1
```

The domain SQL owns deterministic latest-row/window logic. Framework SCD1 owns bounded keyed current-state upsert and tombstone delete mechanics. Health is not artificially converted to SCD2 merely for symmetry with Transport.

## Portable synthetic source

The framework-free path remains under `standalone/`.

Bulk deterministic source data:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_patient.sql
standalone/sql/90_validate.sql
```

Stateful incremental source simulator:

```text
standalone/sql/30_incremental_patient_simulator.sql

DEMO_HEALTH.PATIENT_SIM_CDC
DEMO_HEALTH.PATIENT_SIM_CURRENT
DEMO_HEALTH.PATIENT_SIM_STATE
DEMO_HEALTH.RESET_PATIENT_SIMULATOR()
DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR()
```

`PATIENT_CDC` follows the formal raw/source contract. `PATIENT_DEMO_PROFILE` is explicitly synthetic-only demo data and does not expand the production contract. The simulator models source CDC only; target state/history behavior belongs to the consuming pipeline.

## Processing reset enterprise adapter

Generation-aware processing reset is exposed through `dbt/macros/reset_contract.sql` and the domain recovery boundary. It preserves ingestion-owned Bronze evidence and clears only persisted SCD1 processing state:

```text
AR_HEALTH_RECOVERY
ACTIVE generation N
 -> RESETTING
 -> truncate SILVER_CANONICAL.PATIENT
 -> generation N+1 / READY_FOR_INITIAL_LOAD
 -> rebuild from retained Bronze evidence
 -> ACTIVE
```

The staging view is not truncated. The reset macro rejects prefixed PR/personal workspaces and mismatched environment databases. Repair/replay remains separate from reset. See `docs/RESET_RUNBOOK.md`.

## Verified static state

The v2 migration was verified before merge with:

```text
Metadata v2 CI #24: SUCCESS
Health dbt v2 CI #40: SUCCESS
Standalone SQL CI #15: SUCCESS
```

The PR Workspace job failed closed before Snowflake connection because the required GitHub Environment Snowflake configuration was absent. OIDC token request, Snowflake connection and workspace SQL were not executed.

## Remaining acceptance gates

Portable live acceptance:

```text
plain Snowflake database
no Framework / PLATFORM_CONTROL
-> execute standalone setup + simulator SQL
-> RESET + ADVANCE batches
-> verify deterministic I/U/D source evolution
```

Enterprise live acceptance:

```text
configure DEV Snowflake + GitHub Environment WIF
-> prove PR workspace lifecycle
-> deploy platform/control-plane prerequisites
-> run live patient SCD1 update/tombstone/replay cases
-> prove processing reset/generation rollover and recovery-role isolation
-> run stable deployment
```

A complete same-SHA DEV -> UAT -> PROD promotion orchestrator is intentionally deferred until the live DEV deployment path is proven. Static CI must not be described as live Snowflake proof.
