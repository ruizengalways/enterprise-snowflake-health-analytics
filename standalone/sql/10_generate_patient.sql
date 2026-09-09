-- Synthetic full-change CDC data matching contracts/raw/patient.yml.
-- No row represents a real person.

CREATE OR REPLACE TABLE DEMO_HEALTH.PATIENT_CDC AS
WITH patients AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS patient_n
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),
events AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS event_n
    FROM TABLE(GENERATOR(ROWCOUNT => 4))
),
changes AS (
    SELECT
        p.patient_n,
        e.event_n,
        DATEADD(
            'hour',
            e.event_n * 12 + MOD(p.patient_n, 12),
            '2026-01-01 00:00:00'::TIMESTAMP_NTZ
        ) AS source_updated_at,
        IFF(e.event_n = 0, 'I', IFF(e.event_n = 3 AND MOD(p.patient_n, 25) = 0, 'D', 'U')) AS source_operation
    FROM patients p
    CROSS JOIN events e
)
SELECT
    'PT-' || LPAD(TO_VARCHAR(patient_n + 1), 7, '0') AS patient_id,
    source_updated_at,
    source_operation,
    patient_n * 100 + event_n + 1 AS source_sequence,
    DATEADD('second', 7, source_updated_at) AS ingested_at
FROM changes;

-- Synthetic-only descriptive data for demos; not part of the current RAW contract.
CREATE OR REPLACE TABLE DEMO_HEALTH.PATIENT_DEMO_PROFILE AS
WITH patients AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS patient_n
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
)
SELECT
    'PT-' || LPAD(TO_VARCHAR(patient_n + 1), 7, '0') AS patient_id,
    1940 + MOD(patient_n, 65) AS birth_year,
    CASE MOD(patient_n, 4)
        WHEN 0 THEN 'F'
        WHEN 1 THEN 'M'
        WHEN 2 THEN 'X'
        ELSE 'UNSPECIFIED'
    END AS sex_code,
    'REGION-' || LPAD(TO_VARCHAR(MOD(patient_n, 10) + 1), 2, '0') AS region_code,
    CASE MOD(patient_n, 5)
        WHEN 0 THEN 'HIGH'
        WHEN 1 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS synthetic_risk_band
FROM patients;

CREATE OR REPLACE VIEW DEMO_HEALTH.PATIENT_CURRENT AS
WITH latest AS (
    SELECT
        patient_id,
        source_updated_at,
        source_operation,
        source_sequence,
        ingested_at
    FROM DEMO_HEALTH.PATIENT_CDC
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY patient_id
        ORDER BY source_sequence DESC
    ) = 1
)
SELECT
    l.patient_id,
    l.source_updated_at,
    l.source_operation,
    l.source_sequence,
    l.ingested_at,
    p.birth_year,
    p.sex_code,
    p.region_code,
    p.synthetic_risk_band
FROM latest l
JOIN DEMO_HEALTH.PATIENT_DEMO_PROFILE p
  ON p.patient_id = l.patient_id
WHERE l.source_operation <> 'D';
