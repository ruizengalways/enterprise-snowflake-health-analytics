# Current Context

Concise handoff for a new conversation.

## Active stack

```text
PR #1  feature/domain-operational-contract
  second-domain proof of domain-scoped operational control

PR #2  feature/medallion-one-click-deploy
  Medallion naming, immutable config audit and simplified stable deployment
```

PR #2 is intentionally based on PR #1. Retarget it to `main` after PR #1 merges.

## Framework pin

Verified immutable framework implementation used by this branch:

```text
02e3fca78b453e8a39a1722ce96b15dfc98d7cf8
Framework CI #175: SUCCESS
Bootstrap Contract CI #7: SUCCESS
```

It contains Medallion workspace/target naming, explicit `scd1_merge`, metadata-driven SCD2 + bootstrap contracts, deterministic dataset config snapshots, `PLATFORM_CONTROL.CONFIG` domain helpers, validated stable deployment context and post-build config registration.

Later framework branch commits may be documentation-only; do not repin merely because handoff prose changed.

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

Git is configuration truth. Snowflake CONFIG is immutable deployment audit/readback state.

## Reference dataset

`patient` is the current Health reference dataset. `ehr_mssql` is a reference source identity only; no live SQL Server source connection is claimed.

The RAW contract declares full-change CDC evidence but does not yet declare real business attributes that would be meaningful SCD2 tracked columns. Therefore `patient` is intentionally configured as `scd1_merge` current-state behavior. Transport `vehicle_status` remains the standard SCD2 consumer. Do not fabricate SCD2 tracked columns merely to make Health mirror Transport.

## Deployment UX

After PR #2 is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The wrapper passes the selected workflow revision SHA to the reusable framework workflow, which still requires that SHA to be reachable from current `main` and verifies the exact framework pin.

After successful `dbt build`, validated dataset config snapshots are registered through Health-scoped owner-rights procedures. A failed build is not recorded as a successful deployed configuration.

See `docs/DEPLOYMENT.md`.

## Static proof

Latest verified source/static head before later context-only edits:

```text
1aeafef5e79a76e23153e12df102691f2d6ac724
Metadata CI #15: SUCCESS
dbt Static CI #24: SUCCESS
PR Workspace #5: FAILURE before Snowflake work because ci Environment variables are missing
```

The PR Workspace failure is specifically at `Load approved Snowflake environment configuration`; both `SNOWFLAKE_ACCOUNT` and `SNOWFLAKE_OIDC_AUDIENCE` are empty in the GitHub `ci` Environment.

Static CI proves Health operational isolation, Health CONFIG isolation and Medallion target/profile compatibility.

Live DEV remains required for real authentication, platform grants, cross-domain denial, source behavior, transaction/concurrency semantics, retries/recovery and performance.

## Cross-repository dependencies

```text
framework PR #4 / verified implementation SHA above
platform-infra PR #1 / domain operational/bootstrap surfaces
platform-infra PR #2 / Medallion schemas + PLATFORM_CONTROL.CONFIG
transport PR #3 / reference SCD2 + same thin deployment contract
```

Do not describe this repository as live-deployed until platform DEV bootstrap and WIF are complete.
