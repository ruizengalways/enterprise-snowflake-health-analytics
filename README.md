# Enterprise Snowflake Health Analytics

Reference domain project for a traditional enterprise health-data workload.

## Current status

This repository is a thin domain project that consumes the shared framework through immutable revisions.

Implemented in source/static CI includes:

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
.github/workflows/deploy.yml
```

No live Snowflake dbt deployment, project-CI workspace execution or live SCD2 test has happened yet.

## Workload intent

Health demonstrates batch/micro-batch and CDC-oriented enterprise patterns: SQL Server-like operational sources, confidential/regulated classification, ordered changes, SCD2, late-arriving events, delete/reinsert behavior, reconciliation and production recovery.

Openflow remains deliberately deferred until the live platform/framework foundation is proven.

## Current first dataset contract

`patient` is the first technical contract:

```text
source_system:       ehr_mssql
load_strategy:       scd2_merge
implementation:      standard
business_key:        patient_id
watermark:           source_updated_at
capture archetype:   full_change
capture fidelity:    full_change
checkpoint:          source_position
ordering:            source_sequence
idempotency:         patient_id + source_sequence
change semantics:    CDC + tombstone delete
freshness warning:   60 minutes
freshness error:     120 minutes
reconciliation:      row count + distinct key + timestamp min/max
contract policy:     versioned_contract
```

The RAW grain is one row per patient identifier **and source change**. This is ordered full-change CDC, not a full-table snapshot. The prior `scd2_snapshot` classification is obsolete.

Metadata describes stable engineering behaviour only. Health-specific joins, calculations, clinical/business rules and semantic meaning remain explicit project SQL/tests.

## Framework consumption

The framework owns reusable technical mechanics:

- metadata schemas and semantic validation;
- workspace naming/cleanup and query tags;
- dbt physical target/context resolution;
- standard load/capture/checkpoint/quality primitives;
- SCD1/SCD2 implementations and invariants;
- deterministic SCD2 behavior oracle;
- reusable static CI, PR workspace and stable deployment workflows.

Health owns its RAW contract, dataset configuration, source-specific meaning and business SQL/tests.

The exact currently approved framework SHA is pinned in `dbt/packages.yml` and all workflow callers. Cross-repository release status is tracked centrally in `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` rather than duplicated here.

## dbt target model

Project model SQL must not hard-code physical databases such as `DEV_HEALTH` or `PROD_HEALTH`.

The framework resolver supplies:

```text
DEV personal -> DEV_HEALTH / WH_HEALTH_TRANSFORM / <DEVELOPER>_<LAYER>
PR CI        -> CI_HEALTH  / WH_HEALTH_CI        / PR_<NUMBER>_<LAYER>
DEV deploy   -> DEV_HEALTH / WH_HEALTH_TRANSFORM / stable schemas
UAT deploy   -> UAT_HEALTH / WH_HEALTH_TRANSFORM / stable schemas
PROD deploy  -> PROD_HEALTH / WH_HEALTH_TRANSFORM / stable schemas
```

`dbt/macros/target_wrappers.sql` delegates root-project database/schema naming to the pinned framework dbt package.

The checked-in `profiles.yml` contains no password/private key. Human DEV uses interactive authentication; machine CI/deployment targets use Snowflake workload identity with short-lived GitHub OIDC tokens.

## CI and delivery

`Metadata CI` validates project/dataset/RAW metadata with the pinned framework action.

`dbt Static CI` installs the pinned dbt/framework toolchain and runs offline parsing/contract checks without connecting to Snowflake.

`PR Workspace` is the thin caller for guarded `PR_<n>_*` workspace creation/drop through `SU_GITHUB_HEALTH_CI -> AR_HEALTH_CI`. It becomes live only after the DEV project identity and GitHub Environment `ci` are configured.

`Deploy` is a thin manual caller for the framework stable deployment workflow. It accepts `dev`, `uat` or `prod` plus a full project Git SHA. The framework verifies the SHA belongs to `main` history, checks out the exact revision, verifies the dbt framework pin, enters the protected target GitHub Environment and authenticates as `SU_GITHUB_HEALTH_DEPLOY -> AR_HEALTH_DEPLOY`.

Promotion uses the same reviewed project SHA across DEV -> UAT -> PROD; there are no environment branches.

## Architecture boundary

```text
External Health source
  -> ingestion implementation
  -> project-owned RAW full-change contract
  -> staging
  -> intermediate/canonical
  -> SCD2 / marts
  -> Semantic Views
```

Changing ingestion technology must not force downstream redesign.

For current cross-repository status and live blockers, read `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` first, then `docs/PROJECT_BLUEPRINT.md` in that repository.
