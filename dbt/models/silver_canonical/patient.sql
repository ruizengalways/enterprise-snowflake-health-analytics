{{ enterprise_snowflake_framework.esf_apply_dataset_config('patient') }}

select
    patient_id,
    source_updated_at,
    source_operation,
    source_sequence,
    ingested_at
from {{ ref('stg_patient') }}
qualify row_number() over (
    partition by patient_id
    order by source_updated_at desc, source_sequence desc
) = 1
