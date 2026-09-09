-- Portable Health demo setup.
-- The caller chooses the database, warehouse and role before running this file.

CREATE SCHEMA IF NOT EXISTS DEMO_HEALTH
  COMMENT = 'Portable synthetic Health source data owned by the data repository';
