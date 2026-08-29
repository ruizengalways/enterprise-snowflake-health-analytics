# Enterprise Snowflake Health Analytics

Reference domain project for a traditional enterprise health-data workload.

## Current status

The repository is now a thin executable domain shell rather than a README-only placeholder.

Implemented in source/static CI:

```text
config/project.yml
config/datasets/patient.yml
contracts/raw/patient.yml

dbt/dbt_project.yml
dbt/packages.yml
dbt/profiles.yml
dbt/macros/target_wrappers.sql

.github/workflows/metadata-ci.yml
.github/workflows/dbt-static-ci.yml
.github/workflows/pr-workspace.yml
```

No live Snowflake dbt run or project-CI workspace execution has happened yet.

## Workload intent

Health demonstrates batch/micro-batch and CDC-oriented enterprise patterns: SQL Server-like operational sources, master data, confidential/regulated data classification, SCD2, late-arriving changes, reconciliation and production recovery.

Openflow remains deliberately deferred until the downstream RAW-contract/dbt framework is proven.

## Current first dataset contract

`patient` is the first technical contract:

```text
source_system:       ehr_mssql
load_strategy:       scd2_snapshot
business_key:        patient_id
watermark:           source_updated_at
change semantics:    CDC + tombstone delete
freshness warning:   60 minutes
freshness error:     120 minutes
contract policy:     versioned_contract
```

This metadata describes stable engineering behaviour only. Health-specific joins, calculations, clinical/business rules and semantic meaning remain explicit project SQL/tests.

## Framework consumption

This repo consumes `enterprise-snowflake-data-project-framework` through immutable revisions.

The framework owns:

- metadata schemas/validation;
- workspace naming and PR cleanup;
- query-tag construction;
- dbt physical target resolution;
- reusable static CI;
- future generic load/SCD2/reconciliation/freshness mechanics.

The Health repo owns its RAW contracts, dataset configuration and business SQL.

## dbt target model

Project model SQL must not hard-code physical databases such as `DEV_HEALTH` or `PROD_HEALTH`.

The framework resolver supplies:

```text
DEV personal -> DEV_HEALTH / WH_HEALTH_TRANSFORM / <DEVELOPER>_<LAYER>
PR CI        -> CI_HEALTH  / WH_HEALTH_CI        / PR_<NUMBER>_<LAYER>
UAT          -> UAT_HEALTH / stable layer schemas
PROD         -> PROD_HEALTH / stable layer schemas
```

`dbt/macros/target_wrappers.sql` delegates root-project database/schema naming to the pinned framework dbt package.

The checked-in `profiles.yml` contains no password/private key. Human DEV defaults to external-browser authentication; machine targets are designed for Snowflake workload identity with short-lived OIDC tokens.

## CI

`Metadata CI` validates project/dataset/RAW metadata using the pinned framework composite action.

`dbt Static CI` installs the pinned dbt Core/Snowflake adapter baseline, resolves an offline CI target, installs packages and runs `dbt parse` without connecting to Snowflake.

`PR Workspace` is the thin caller for the framework's Snowflake workspace lifecycle. It will become live only after the DEV project-CI Snowflake service identity and GitHub Environment are applied/configured.

## Architecture boundary

```text
External Health source
  -> ingestion implementation
  -> project-owned RAW contract
  -> staging
  -> intermediate/canonical
  -> SCD2 / marts
  -> semantic views
```

Changing ingestion technology must not force downstream redesign.

For current cross-repository status, read `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` first, then `docs/PROJECT_BLUEPRINT.md` in that repository.
