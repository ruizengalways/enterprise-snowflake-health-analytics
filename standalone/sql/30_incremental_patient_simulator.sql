-- Stateful synthetic patient source simulator.
-- Pure Snowflake SQL Scripting; standalone and platform-agnostic.
--
-- Usage:
--   CALL DEMO_HEALTH.RESET_PATIENT_SIMULATOR();
--   CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR(); -- initial I batch
--   CALL DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR(); -- deterministic U batch
--
-- The simulator writes to its own objects so the bulk generator remains available.

CREATE TABLE IF NOT EXISTS DEMO_HEALTH.PATIENT_SIM_CDC (
    patient_id         VARCHAR         NOT NULL,
    source_updated_at  TIMESTAMP_NTZ   NOT NULL,
    source_operation   VARCHAR         NOT NULL,
    source_sequence    NUMBER          NOT NULL,
    ingested_at        TIMESTAMP_NTZ   NOT NULL
);

CREATE TABLE IF NOT EXISTS DEMO_HEALTH.PATIENT_SIM_STATE (
    simulator_name VARCHAR PRIMARY KEY,
    current_batch  NUMBER NOT NULL,
    updated_at     TIMESTAMP_NTZ NOT NULL
);

MERGE INTO DEMO_HEALTH.PATIENT_SIM_STATE target
USING (SELECT 'patient' simulator_name, -1 current_batch) source
   ON target.simulator_name = source.simulator_name
WHEN NOT MATCHED THEN INSERT (simulator_name, current_batch, updated_at)
VALUES (source.simulator_name, source.current_batch, CURRENT_TIMESTAMP());

CREATE OR REPLACE VIEW DEMO_HEALTH.PATIENT_SIM_CURRENT AS
SELECT
    patient_id,
    source_updated_at,
    source_operation,
    source_sequence,
    ingested_at
FROM DEMO_HEALTH.PATIENT_SIM_CDC
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY patient_id
    ORDER BY source_sequence DESC
) = 1
AND source_operation <> 'D';

CREATE OR REPLACE PROCEDURE DEMO_HEALTH.RESET_PATIENT_SIMULATOR()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE DEMO_HEALTH.PATIENT_SIM_CDC;

    UPDATE DEMO_HEALTH.PATIENT_SIM_STATE
       SET current_batch = -1,
           updated_at = CURRENT_TIMESTAMP()
     WHERE simulator_name = 'patient';

    RETURN 'patient simulator reset; next ADVANCE emits initial inserts';
END;
$$;

CREATE OR REPLACE PROCEDURE DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_batch NUMBER;
    v_event_time TIMESTAMP_NTZ;
    v_rows NUMBER;
BEGIN
    SELECT current_batch + 1
      INTO :v_batch
      FROM DEMO_HEALTH.PATIENT_SIM_STATE
     WHERE simulator_name = 'patient';

    v_event_time := DATEADD('minute', v_batch * 30, '2026-01-01 00:00:00'::TIMESTAMP_NTZ);

    IF (v_batch = 0) THEN
        INSERT INTO DEMO_HEALTH.PATIENT_SIM_CDC (
            patient_id, source_updated_at, source_operation, source_sequence, ingested_at
        )
        SELECT
            'PT-' || LPAD(TO_VARCHAR(patient_n + 1), 7, '0'),
            :v_event_time,
            'I',
            patient_n * 1000 + :v_batch + 1,
            DATEADD('second', 5, :v_event_time)
        FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS patient_n
            FROM TABLE(GENERATOR(ROWCOUNT => 1000))
        );
    ELSE
        INSERT INTO DEMO_HEALTH.PATIENT_SIM_CDC (
            patient_id, source_updated_at, source_operation, source_sequence, ingested_at
        )
        SELECT
            'PT-' || LPAD(TO_VARCHAR(patient_n + 1), 7, '0'),
            :v_event_time,
            IFF(
                :v_batch >= 5
                AND MOD(patient_n, 100) = MOD(10 - MOD(:v_batch, 10), 10),
                'D',
                'U'
            ),
            patient_n * 1000 + :v_batch + 1,
            DATEADD('second', 5, :v_event_time)
        FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS patient_n
            FROM TABLE(GENERATOR(ROWCOUNT => 1000))
        )
        WHERE MOD(patient_n + :v_batch, 10) = 0;
    END IF;

    v_rows := SQLROWCOUNT;

    UPDATE DEMO_HEALTH.PATIENT_SIM_STATE
       SET current_batch = :v_batch,
           updated_at = CURRENT_TIMESTAMP()
     WHERE simulator_name = 'patient';

    RETURN 'patient simulator advanced to batch ' || v_batch || '; emitted rows=' || v_rows;
END;
$$;
