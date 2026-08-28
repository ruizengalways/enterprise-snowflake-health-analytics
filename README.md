# Enterprise Snowflake Health Analytics

Reference data project for a traditional enterprise workload.

## Workload intent

Health will demonstrate characteristics such as batch/micro-batch, SQL Server-like operational sources, CDC, master data, PII, SCD2, late-arriving changes, reconciliation and strong production recovery requirements.

## This repository owns

- Health project configuration
- Health dataset metadata
- Health RAW contracts
- Health source mappings
- Health-specific dbt SQL and business rules
- Health-specific tests and semantic definitions
- Health-specific ingestion configuration where required

## This repository consumes

Reusable technical behaviour from `enterprise-snowflake-data-project-framework` through versioned dependencies.

It should not reimplement generic SCD2 mechanics, reconciliation/freshness engines, audit logging, rollback/recovery workflows or shared CI/CD when those capabilities belong in the framework.

## Architecture boundary

```text
External Health source
  -> ingestion implementation
  -> HEALTH_RAW contract
  -> staging
  -> canonical/intermediate
  -> SCD2 / marts
  -> semantic
```

The downstream pipeline must work before Openflow is introduced. Openflow is deferred to the final ingestion phase.

The canonical platform architecture is maintained in `enterprise-snowflake-platform-infra/docs/PROJECT_BLUEPRINT.md`.