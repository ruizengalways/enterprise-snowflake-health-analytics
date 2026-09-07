-- Human-readable validation queries. Expected results are documented below.

SELECT COUNT(*) AS patient_change_rows
FROM DEMO_HEALTH.PATIENT_CDC;
-- expected: 4000

SELECT source_operation, COUNT(*) AS rows_by_operation
FROM DEMO_HEALTH.PATIENT_CDC
GROUP BY source_operation
ORDER BY source_operation;
-- expected: I, U and D are all present

SELECT COUNT(*) AS patient_profile_rows
FROM DEMO_HEALTH.PATIENT_DEMO_PROFILE;
-- expected: 1000

SELECT COUNT(*) AS current_patient_rows
FROM DEMO_HEALTH.PATIENT_CURRENT;
-- expected: 960 (40 deterministic tombstone deletes)

SELECT COUNT(*) AS duplicate_patient_events
FROM (
    SELECT patient_id, source_sequence
    FROM DEMO_HEALTH.PATIENT_CDC
    GROUP BY patient_id, source_sequence
    HAVING COUNT(*) > 1
);
-- expected: 0
