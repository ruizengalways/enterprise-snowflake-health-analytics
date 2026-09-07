# Current Context

Concise handoff for a new conversation.

## Architectural rule

Health now has a **framework-independent portable core**. Source contracts and synthetic data generation must work on any Snowflake platform without the enterprise framework, `PLATFORM_CONTROL`, Terraform, WIF, enterprise RBAC, or enterprise database/warehouse naming.

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
PR #4 framework-free portable synthetic data
```

PR #4 is stacked on PR #3 while the lower stack remains open.

## Portable demo — PR #4

Run on any caller-selected Snowflake database/warehouse:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_patient.sql
standalone/sql/90_validate.sql
```

Creates only:

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` matches the formal RAW contract. `PATIENT_DEMO_PROFILE` is explicitly synthetic-only demo data and does not silently expand the production contract. No row represents a real person.

The SQL creates no database/warehouse/role and contains no framework or `PLATFORM_CONTROL` reference.

Verified portability source/static head:

```text
d6374e9c694073456ca51e5c2a454fee052e26c7
Standalone SQL CI #1: SUCCESS
PR Workspace #18: enterprise adapter workflow; live environment configuration remains external
```

Later branch commits are documentation-only. The standalone CI proof is independent of the enterprise workspace workflow.

## Optional enterprise adapter

Current reset-aware framework pin used only by the enterprise dbt/workflow path:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

Enterprise stable databases use `<ENV>_HEALTH` plus Medallion schemas. Those names are not portable-core requirements.

## Reference dataset

`patient` remains a full-change CDC reference dataset and intentionally uses `scd1_merge` in the enterprise adapter because the formal RAW contract currently lacks real business attributes suitable for SCD2 tracking.

The portable demo provides CDC evidence plus a separately labeled synthetic profile for dashboard experiments without claiming a live EHR source.

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
 -> execute standalone SQL
 -> verify row counts, keys and CDC operations
```

Enterprise live acceptance separately requires real DEV Snowflake/WIF for grants, control plane, reset generation rollover and pipelines.
