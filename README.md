# Enterprise Snowflake Health Analytics

Domain repository for Health-owned Snowflake analytics.

## Start here

For a new conversation/session, read:

1. `docs/CURRENT_CONTEXT.md` — current PR/branch, framework pin, CI status, blockers and next gate.
2. `docs/DEPLOYMENT.md` — one-click stable deployment path and environment prerequisites.

Human-readable architecture and operating guidance belong under `docs/`. Machine configuration belongs under `config/` and `contracts/`. Reusable technical behavior belongs in `enterprise-snowflake-data-project-framework` rather than being copied here.

## Domain database shape

Stable Health databases are environment × data product:

```text
DEV_HEALTH
UAT_HEALTH
PROD_HEALTH
```

They use the shared Medallion schema vocabulary:

```text
BRONZE
SILVER_STAGING
SILVER_INTERMEDIATE
SILVER_CANONICAL
GOLD_MARTS
GOLD_SEMANTIC
DQ
```

Ordinary new physical sources do not require a new database or Terraform-created source schema. Source identity stays in Git metadata and Bronze object naming unless governance requires an explicit isolation exception.

## Current reference dataset

`patient` is the current Health reference dataset. Its RAW contract demonstrates a full-change/CDC-style source contract and domain-safe operational control usage. `ehr_mssql` is a reference source identity; this repository does not yet claim a live SQL Server connection.

The current patient contract intentionally uses `scd1_merge`. The reference RAW contract does not yet contain real business attributes suitable for SCD2 tracking, so the project does not invent tracked columns simply to mirror another domain. Transport `vehicle_status` remains the standard SCD2 reference consumer.

## Control plane

Health project runtime/deployment code uses only Health-scoped platform surfaces:

```text
PLATFORM_CONTROL.OPERATIONS.HEALTH_*
PLATFORM_CONTROL.CONFIG.HEALTH_*
```

Project roles must not directly DML shared PLATFORM_CONTROL base tables.

Git remains the dataset configuration source of truth. A successful stable deployment records the validated immutable config snapshot through the Health-scoped CONFIG procedure.

## Delivery

PR CI uses framework-generated `PR_<number>_<MEDALLION_LAYER>` workspaces.

Stable DEV/UAT/PROD deployment is exposed through `.github/workflows/deploy.yml`. After a change is on `main`, use GitHub Actions -> Deploy -> Run workflow and choose only the target environment. The selected workflow revision SHA is passed to the pinned reusable framework deployment workflow, which independently proves that the revision is reachable from `main`.

The reusable workflow validates Git metadata, derives dbt context, authenticates through protected-environment WIF, runs `dbt build`, and registers config snapshots only after a successful build.

See `docs/DEPLOYMENT.md` for the operator path and prerequisites.

## Proof boundary

Static CI proves metadata validation, dbt offline rendering, Health-scoped operational/config API usage and framework-pin consistency.

Live Snowflake WIF, platform grants, cross-domain denial, real source behavior, retries/recovery and performance remain explicit DEV integration gates.
