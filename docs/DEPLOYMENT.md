# Deployment

## Preferred operator experience

Stable deployment is intentionally a thin wrapper over the reusable framework workflow.

After the desired revision is merged to `main`:

1. Open **GitHub Actions**.
2. Select **Deploy**.
3. Ensure the workflow is being run from `main`.
4. Choose `dev`, `uat` or `prod`.
5. Select **Run workflow**.

There is no project SHA text box. The wrapper passes the selected workflow revision (`github.sha`) to the framework, and the reusable workflow independently verifies that the revision is reachable from current `main` history.

## Reusable deployment sequence

```text
validate immutable project/framework revisions
  -> enter protected GitHub Environment
  -> load SNOWFLAKE_ACCOUNT + account-scoped SNOWFLAKE_OIDC_AUDIENCE
  -> checkout project main history and exact requested revision
  -> verify dbt package pin == framework revision
  -> validate Git project/dataset/RAW metadata
  -> resolve DEV/UAT/PROD database, warehouse and SILVER_STAGING default
  -> build bounded dbt vars + deterministic dataset config snapshots
  -> request short-lived Snowflake WIF token
  -> dbt debug
  -> dbt build
  -> register config snapshots through HEALTH-scoped owner-rights procedures
```

Config snapshots are registered only after `dbt build` succeeds.

## Required platform/GitHub setup

Each protected GitHub Environment (`dev`, `uat`, `prod`) must define:

```text
SNOWFLAKE_ACCOUNT
SNOWFLAKE_OIDC_AUDIENCE
```

The corresponding Snowflake account must already contain platform-managed objects including:

```text
SU_GITHUB_HEALTH_DEPLOY
AR_HEALTH_DEPLOY
WH_HEALTH_TRANSFORM
<ENV>_HEALTH with Medallion schemas
PLATFORM_CONTROL.OPERATIONS.HEALTH_*
PLATFORM_CONTROL.CONFIG.HEALTH_*
```

The platform-infra repository owns these objects. This domain repository does not bootstrap account-level infrastructure.

## Promotion

Promote the same project Git revision across environments:

```text
same SHA
DEV -> UAT -> PROD
```

Do not maintain environment branches or rebuild different source revisions for each environment.

## Fail-closed behavior

Deployment fails when any of these invariants is not met:

- requested revision is not reachable from `main`;
- project `dbt/packages.yml` does not pin the exact framework revision used by the workflow;
- metadata validation fails;
- protected-environment WIF variables are missing/invalid;
- Snowflake identity/grants are not ready;
- `dbt build` fails;
- dataset config snapshot registration fails.

A failed build does not create a successful deployment config snapshot.

## Current live boundary

The workflow is implemented, but live execution still depends on real Snowflake accounts and GitHub Environment WIF configuration. Static CI success is not evidence that a live deployment has already occurred.
