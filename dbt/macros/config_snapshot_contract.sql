{% macro health_patient_config_snapshot_contract_sql() -%}
    {%- set read_sql -%}
{{ enterprise_snowflake_framework.esf_domain_dataset_config_read_sql(
    'HEALTH',
    'patient'
) }}
    {%- endset -%}

    {%- set register_sql -%}
{{ enterprise_snowflake_framework.esf_domain_register_dataset_config_call_sql(
    'HEALTH',
    'patient',
    '1111111111111111111111111111111111111111'
) }}
    {%- endset -%}

    {{ log(
        '---CONFIG_SNAPSHOT_READ---\n' ~ read_sql
        ~ '\n---CONFIG_SNAPSHOT_REGISTER---\n' ~ register_sql,
        info=true
    ) }}
    {{ return('Health dataset config snapshot contract rendered') }}
{%- endmacro %}
