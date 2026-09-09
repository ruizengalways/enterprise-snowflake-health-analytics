{#
  Explicit Health v2 processing-reset plan.

  This reset deliberately preserves BRONZE source evidence. Source -> Bronze is
  ingestion-owned; the enterprise processing reset clears only reconstructable
  downstream state and lets the normal pipeline rebuild from landed evidence.
#}

{% macro health_patient_reset_database() -%}
    {%- set environment = env_var('ESF_ENVIRONMENT', '') | lower | trim -%}
    {%- set expected_databases = {
        'dev': 'DEV_HEALTH',
        'uat': 'UAT_HEALTH',
        'prod': 'PROD_HEALTH'
    } -%}
    {%- set expected = expected_databases.get(environment) -%}
    {%- if expected is none -%}
        {{ exceptions.raise_compiler_error('Health full reset requires ESF_ENVIRONMENT=dev|uat|prod') }}
    {%- endif -%}
    {%- set actual = target.database | string | upper | trim -%}
    {%- if actual != expected -%}
        {{ exceptions.raise_compiler_error('Health full reset database mismatch: expected ' ~ expected ~ ', got ' ~ actual) }}
    {%- endif -%}
    {%- if env_var('ESF_SCHEMA_PREFIX', '') | trim != '' -%}
        {{ exceptions.raise_compiler_error('Health full reset is forbidden in prefixed PR/personal workspaces') }}
    {%- endif -%}
    {{ return(actual) }}
{%- endmacro %}

{% macro health_patient_reset_relations() -%}
    {%- set database = health_patient_reset_database() -%}
    {{ return([
        database ~ '.SILVER_CANONICAL.PATIENT'
    ]) }}
{%- endmacro %}

{% macro health_patient_full_reset_contract_sql(
    reset_id='static-reset-contract',
    reason='static reset contract',
    git_sha=none
) -%}
    {%- set sql = enterprise_snowflake_framework.esf_dataset_full_reset_sql(
        'HEALTH',
        reset_id,
        'patient',
        reason,
        health_patient_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'PROCESSING_FULL_RESET', 'dataset', 'patient', 'bronze_preserved', TRUE)"
    ) -%}
    {%- do log(sql, info=true) -%}
    {{ return(sql) }}
{%- endmacro %}

{% macro health_patient_full_reset(reset_id, reason, git_sha=none) -%}
    {{ return(enterprise_snowflake_framework.esf_execute_dataset_full_reset(
        'HEALTH',
        reset_id,
        'patient',
        reason,
        health_patient_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'PROCESSING_FULL_RESET', 'dataset', 'patient', 'bronze_preserved', TRUE)"
    )) }}
{%- endmacro %}
