from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"


class StandaloneHealthSqlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.files = sorted(SQL_DIR.glob("*.sql"))
        cls.sql = "\n".join(path.read_text(encoding="utf-8") for path in cls.files).upper()

    def test_has_expected_portable_scripts(self) -> None:
        self.assertEqual(
            {path.name for path in self.files},
            {
                "00_setup.sql",
                "10_generate_patient.sql",
                "30_incremental_patient_simulator.sql",
                "90_validate.sql",
                "99_cleanup.sql",
            },
        )

    def test_has_no_enterprise_platform_dependency(self) -> None:
        for forbidden in (
            "ENTERPRISE_SNOWFLAKE_FRAMEWORK",
            "PLATFORM_CONTROL",
            "CREATE DATABASE",
            "USE DATABASE",
            "USE ROLE",
            "USE WAREHOUSE",
            "AR_HEALTH_",
            "WH_HEALTH_",
            "DEV_HEALTH",
            "UAT_HEALTH",
            "PROD_HEALTH",
        ):
            self.assertNotIn(forbidden, self.sql)

    def test_patient_raw_contract_columns_are_present(self) -> None:
        patient_sql = (SQL_DIR / "10_generate_patient.sql").read_text(encoding="utf-8").upper()
        for column in (
            "PATIENT_ID",
            "SOURCE_UPDATED_AT",
            "SOURCE_OPERATION",
            "SOURCE_SEQUENCE",
            "INGESTED_AT",
        ):
            self.assertIn(column, patient_sql)
        self.assertIn("'I'", patient_sql)
        self.assertIn("'U'", patient_sql)
        self.assertIn("'D'", patient_sql)

    def test_descriptive_profile_is_explicitly_synthetic(self) -> None:
        patient_sql = (SQL_DIR / "10_generate_patient.sql").read_text(encoding="utf-8").upper()
        self.assertIn("PATIENT_DEMO_PROFILE", patient_sql)
        self.assertIn("SYNTHETIC_RISK_BAND", patient_sql)
        self.assertIn("NO ROW REPRESENTS A REAL PERSON", patient_sql)

    def test_incremental_simulator_is_native_sql_and_stateful(self) -> None:
        simulator_sql = (SQL_DIR / "30_incremental_patient_simulator.sql").read_text(encoding="utf-8").upper()
        self.assertIn("CREATE OR REPLACE PROCEDURE DEMO_HEALTH.RESET_PATIENT_SIMULATOR()", simulator_sql)
        self.assertIn("CREATE OR REPLACE PROCEDURE DEMO_HEALTH.ADVANCE_PATIENT_SIMULATOR()", simulator_sql)
        self.assertIn("LANGUAGE SQL", simulator_sql)
        self.assertNotIn("LANGUAGE PYTHON", simulator_sql)
        self.assertIn("PATIENT_SIM_STATE", simulator_sql)
        self.assertIn("CURRENT_BATCH", simulator_sql)
        self.assertIn("PATIENT_SIM_CDC", simulator_sql)
        self.assertIn("PATIENT_SIM_CURRENT", simulator_sql)
        self.assertIn("'I'", simulator_sql)
        self.assertIn("'U'", simulator_sql)
        self.assertIn("'D'", simulator_sql)
        self.assertIn(":V_BATCH >= 5", simulator_sql)
        self.assertIn("MOD(PATIENT_N, 100)", simulator_sql)


if __name__ == "__main__":
    unittest.main()
