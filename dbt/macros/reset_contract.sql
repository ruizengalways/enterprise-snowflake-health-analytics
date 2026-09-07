{#
  Explicit Health full-reset plan.

  Repair/replay does not use this macro. Full reset abandons the current patient
  generation and clears reconstructable data before the main pipeline is run again.
#}

{% macro health_patient_reset_relations() -%}
    {%- set database = target.database | upper -%}
    {{ return([
        database ~ '.BRONZE.PATIENT',
        database ~ '.SILVER_STAGING.PATIENT',
        database ~ '.SILVER_INTERMEDIATE.PATIENT',
        database ~ '.SILVER_CANONICAL.PATIENT',
        database ~ '.GOLD_MARTS.PATIENT'
    ]) }}
{%- endmacro %}

{% macro health_patient_full_reset_contract_sql(
    reset_id='static-reset-contract',
    reason='static reset contract',
    git_sha=none
) -%}
    {{ enterprise_snowflake_framework.esf_dataset_full_reset_sql(
        'HEALTH',
        reset_id,
        'patient',
        reason,
        health_patient_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'FULL_RESET', 'dataset', 'patient')"
    ) }}
{%- endmacro %}

{% macro health_patient_full_reset(reset_id, reason, git_sha=none) -%}
    {{ return(enterprise_snowflake_framework.esf_execute_dataset_full_reset(
        'HEALTH',
        reset_id,
        'patient',
        reason,
        health_patient_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'FULL_RESET', 'dataset', 'patient')"
    )) }}
{%- endmacro %}
