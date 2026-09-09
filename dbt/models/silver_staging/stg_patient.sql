{{ config(materialized='view') }}

select
    patient_id,
    source_updated_at,
    source_operation,
    source_sequence,
    ingested_at
from {{ source('bronze_health', 'patient') }}
