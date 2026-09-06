# Current Context

Concise handoff for a new conversation.

## Active work

```text
PR #1  feature/domain-operational-contract
  second-domain proof of domain-scoped operational control

current stacked branch
  feature/medallion-one-click-deploy
  adds Medallion naming, immutable config audit and simplified stable deployment
```

The current branch is intentionally based on PR #1. Retarget it to `main` after PR #1 merges.

## Framework pin

Current immutable framework revision:

```text
02e3fca78b453e8a39a1722ce96b15dfc98d7cf8
```

That revision has green Framework CI and Bootstrap Contract CI and contains:

```text
Medallion workspace/target naming
explicit scd1_merge
metadata-driven SCD2 + bootstrap contracts
deterministic dataset config snapshots
PLATFORM_CONTROL.CONFIG domain API helpers
validated stable deployment context
post-build config snapshot registration
```

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

## Control-plane contract

Runtime state is accessed through:

```text
PLATFORM_CONTROL.OPERATIONS.HEALTH_*
```

Deployment config audit is accessed through:

```text
PLATFORM_CONTROL.CONFIG.HEALTH_DATASET_CONFIG_SNAPSHOT
PLATFORM_CONTROL.CONFIG.HEALTH_REGISTER_DATASET_CONFIG_SNAPSHOT
```

Git is configuration truth. Snowflake CONFIG is immutable deployment audit/readback state.

## Current reference dataset

`patient` is the current Health reference dataset. `ehr_mssql` is a reference source identity only; no live SQL Server source connection is claimed.

## Deployment UX

After the branch is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The wrapper passes the selected workflow revision SHA to the reusable framework deploy workflow and the framework still enforces the immutable-main-history guard.

Successful deployment registers validated dataset config snapshots only after `dbt build`. See `docs/DEPLOYMENT.md`.

## Expected proof boundary

Static CI should prove:

```text
Metadata CI
dbt Static CI
  Health operational isolation
  Health CONFIG isolation
  Medallion target/profile compatibility
```

PR Workspace still requires a real Snowflake `ci` GitHub Environment/WIF configuration and may fail for that external reason.

Live DEV remains required for account authentication, platform grants, cross-domain denial, real source behavior, runtime transactions/concurrency, retries/recovery and performance.

## Cross-repository dependencies

```text
framework PR #4 / green SHA above
platform-infra PR #1 / domain operational/bootstrap surfaces
platform-infra PR #2 / Medallion schemas + PLATFORM_CONTROL.CONFIG
```

Do not describe this repository as live-deployed until platform DEV bootstrap and WIF are complete.
