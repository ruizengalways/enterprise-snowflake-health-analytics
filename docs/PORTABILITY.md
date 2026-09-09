# Health repository portability contract

## Goal

A Health data repository must remain useful outside the enterprise Snowflake platform.

A team must be able to clone this repository, connect to an unrelated Snowflake account, and generate representative synthetic source data without installing or knowing about the enterprise data framework.

## Portable core

The portable core is:

```text
contracts/
config/
standalone/
domain documentation
```

Rules for the portable core:

- no dependency on `enterprise-snowflake-data-project-framework`;
- no dependency on `PLATFORM_CONTROL`;
- no Terraform requirement;
- no required `AR_*` role names;
- no required enterprise warehouse names;
- no `DEV_HEALTH` / `UAT_HEALTH` / `PROD_HEALTH` database assumption;
- no GitHub WIF requirement;
- synthetic data must run as ordinary Snowflake SQL in the caller-selected database;
- domain source shapes are owned by this repository's contracts, not by a framework package.

`standalone/tests/test_standalone_sql.py` enforces the most important negative dependencies in CI.

## Optional enterprise adapter

The existing `dbt/` and enterprise GitHub workflows are an adapter for the `enterprise-snowflake` platform. They may depend on shared framework capabilities such as:

```text
PLATFORM_CONTROL integration
Medallion deployment conventions
bootstrap/reset helpers
WIF deployment workflows
```

Those dependencies must not leak into `standalone/` or become prerequisites for consuming the source contracts.

Dependency direction is therefore:

```text
portable Health domain core
          ↑
optional enterprise adapter
          ↑
enterprise framework/platform
```

The framework may help operate the domain project; it must not own the domain's source contract or be required to create demo data.

## Synthetic source contract

The framework-free demo currently creates:

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` aligns to `contracts/raw/patient.yml`. `PATIENT_DEMO_PROFILE` is deliberately synthetic-only and is not silently treated as part of the production RAW contract.

This allows another Snowflake platform to build its own transformations, dbt project, Dynamic Tables, Streams/Tasks, Snowpark pipeline or other implementation on top of the same source evidence.

## What portability does not mean

Portability does not require every platform to use the same schemas, roles, control tables, orchestration, history strategy or deployment workflow.

The stable contract is the domain data shape and meaning. Enterprise implementation conventions remain optional.
