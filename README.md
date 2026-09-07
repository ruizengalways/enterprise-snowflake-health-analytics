# Enterprise Snowflake Health Analytics

Health data-product repository. The **portable core is framework-independent**: the repository can generate and expose synthetic Health source data on any Snowflake platform without the enterprise data framework, `PLATFORM_CONTROL`, Terraform, or enterprise-specific RBAC/database naming.

## Start here

1. `standalone/README.md` — run synthetic Health data on any Snowflake account.
2. `docs/PORTABILITY.md` — portable-core versus optional enterprise-integration boundary.
3. `docs/CURRENT_CONTEXT.md` — current PR stack, CI status and live blockers.
4. `docs/DEPLOYMENT.md` — optional enterprise-platform deployment path.

## Portable core

The portable core is owned by this repository and must not depend on a shared implementation framework:

```text
contracts/
config/                 domain metadata
standalone/             pure Snowflake SQL synthetic sources
docs/                   domain knowledge and operating guidance
```

To generate demo data, select any Snowflake database/warehouse and run:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_patient.sql
standalone/sql/90_validate.sql
```

This creates:

```text
DEMO_HEALTH.PATIENT_CDC
DEMO_HEALTH.PATIENT_DEMO_PROFILE
DEMO_HEALTH.PATIENT_CURRENT
```

`PATIENT_CDC` matches the current RAW contract. `PATIENT_DEMO_PROFILE` is explicitly synthetic-only descriptive data for demos and dashboard experiments; it does not silently expand the production RAW contract. No row represents a real person.

No enterprise framework installation is needed. `Standalone SQL CI` enforces that these scripts contain no `PLATFORM_CONTROL`, enterprise role/warehouse/database names, or framework references.

## Domain contract

`patient` is the current Health reference dataset. Its RAW contract is a full-change CDC-style source contract and currently uses `scd1_merge` in the enterprise integration because the formal RAW contract does not yet declare real business attributes appropriate for SCD2 tracking.

The standalone source shape remains usable by another Snowflake platform regardless of how that platform performs ingestion or transformation.

## Optional enterprise integration

The existing `dbt/` project and GitHub deployment workflows integrate this portable domain repo with the `enterprise-snowflake` platform. That path may use the enterprise framework for control-plane, deployment, reset, bootstrap and WIF conveniences.

It is an **adapter**, not a prerequisite for using the repository or generating demo data. A consumer on another Snowflake platform may ignore the enterprise integration and use the portable contracts/SQL directly.

Enterprise stable databases currently use:

```text
DEV_HEALTH / UAT_HEALTH / PROD_HEALTH
BRONZE / SILVER_STAGING / SILVER_INTERMEDIATE / SILVER_CANONICAL
GOLD_MARTS / GOLD_SEMANTIC / DQ
```

Those names are enterprise-platform conventions, not requirements of the portable core.

## Proof boundary

Standalone CI proves the synthetic SQL has no enterprise-framework/platform dependency and that expected contract columns are present. Enterprise static CI separately proves the optional platform adapter.

Neither static suite is a live Snowflake execution proof. Real Snowflake WIF, grants, cross-domain denial, reset runtime behavior and source CDC semantics remain live integration gates.
