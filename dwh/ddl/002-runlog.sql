-- 002: ETL run-log + rekonsiliasiya (plan: "rekonsiliasiya PoC-nin mərkəzi məhsuludur")

CREATE SCHEMA IF NOT EXISTS etl;

CREATE TABLE etl.run_log (
  run_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  started_at    timestamptz NOT NULL DEFAULT now(),
  finished_at   timestamptz,
  step          text NOT NULL,            -- extract|transform|reconcile|stock_eod|...
  status        text NOT NULL DEFAULT 'running',  -- running|ok|failed
  rows_affected bigint,
  window_from   date,
  window_to     date,
  message       text
);

-- Gün-bə-gün kontrol cəmlər: mənbə (1C) vs DWH. Uyğunsuz gün avtomatik
-- re-extract növbəsinə düşür ("repair") və trust-dashboard-da görünür.
CREATE TABLE etl.recon_daily (
  check_date    date NOT NULL,
  metric        text NOT NULL,            -- doc_count|revenue_gross|vat|qty|stock_value
  source_value  numeric(20,4),
  dwh_value     numeric(20,4),
  diff          numeric(20,4) GENERATED ALWAYS AS (COALESCE(source_value,0) - COALESCE(dwh_value,0)) STORED,
  status        text NOT NULL DEFAULT 'pending',  -- ok|mismatch|repaired|pending
  run_id        bigint REFERENCES etl.run_log(run_id),
  checked_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (check_date, metric)
);

-- NL→SQL audit (Phase 5): hər sual, generasiya olunan SQL, icra nəticəsi
CREATE TABLE etl.nl_audit (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  asked_at      timestamptz NOT NULL DEFAULT now(),
  username      text,
  question      text NOT NULL,
  generated_sql text,
  was_executed  boolean NOT NULL DEFAULT false,
  duration_ms   int,
  row_count     int,
  error         text
);

-- report_ro yalnız mart.* görür (000-da yaradılan rol üçün)
GRANT USAGE ON SCHEMA mart TO report_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA mart TO report_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA mart GRANT SELECT ON TABLES TO report_ro;
