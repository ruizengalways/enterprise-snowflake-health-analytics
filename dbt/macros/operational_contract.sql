{% macro health_operational_contract_sql() -%}
    {%- set checkpoint_read_sql -%}
{{ enterprise_snowflake_framework.esf_domain_checkpoint_read_sql('HEALTH', 'patient', 'source_position') }}
    {%- endset -%}

    {%- set checkpoint_advance_sql -%}
{{ enterprise_snowflake_framework.esf_domain_checkpoint_advance_call_sql(
    'HEALTH', 'patient', 'source_position',
    "object_construct('source_sequence', 12345)",
    'batch-smoke-123', '0000000000000000000000000000000000000000'
) }}
    {%- endset -%}

    {%- set run_start_sql -%}
{{ enterprise_snowflake_framework.esf_domain_pipeline_run_start_call_sql(
    'HEALTH', 'run-smoke-123', 1, 'patient_capture', 'patient',
    '0000000000000000000000000000000000000000',
    "object_construct('project', 'health', 'workload', 'static_ci')",
    "object_construct('source_sequence', 12344)"
) }}
    {%- endset -%}

    {%- set run_finish_sql -%}
{{ enterprise_snowflake_framework.esf_domain_pipeline_run_finish_call_sql(
    'HEALTH', 'run-smoke-123', 1, 'SUCCEEDED',
    "object_construct('source_sequence', 12345)",
    '100', '100', '100', '0', '0', none, none,
    "object_construct('mode', 'static_ci')"
) }}
    {%- endset -%}

    {%- set check_query -%}
select
    'freshness' as check_type,
    'patient_freshness' as check_name,
    'PASS' as status,
    'age_minutes' as measure_name,
    to_variant(1) as observed_value,
    object_construct('warn_after_minutes', 60, 'error_after_minutes', 120) as expected_value,
    object_construct('mode', 'static_ci') as details
    {%- endset -%}

    {%- set check_record_sql -%}
{{ enterprise_snowflake_framework.esf_domain_record_check_result_sql(
    'HEALTH', check_query, 'run-smoke-123', 1, 'patient'
) }}
    {%- endset -%}

    {{ log(
        '---HEALTH_CHECKPOINT_READ---\n' ~ checkpoint_read_sql
        ~ '\n---HEALTH_CHECKPOINT_ADVANCE---\n' ~ checkpoint_advance_sql
        ~ '\n---HEALTH_RUN_START---\n' ~ run_start_sql
        ~ '\n---HEALTH_RUN_FINISH---\n' ~ run_finish_sql
        ~ '\n---HEALTH_CHECK_RESULT---\n' ~ check_record_sql,
        info=true
    ) }}
    {{ return('health operational contract SQL rendered') }}
{%- endmacro %}
