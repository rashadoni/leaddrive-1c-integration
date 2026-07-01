-- 000: docker-entrypoint-initdb.d ilk faylı — Metabase üçün ayrıca app-db.
-- (POSTGRES_DB=pharma_dwh konteyner tərəfindən yaradılır; bu skript onun içində işləyir.)
CREATE DATABASE metabase_app;

-- NL→SQL üçün məhdud read-only rol (yalnız mart.* view-larına GRANT veriləcək — 002-yə bax)
-- DİQQƏT: dev parolu. Bu rol NL→SQL-in təhlükəsizlik sərhədidir — test maşını
-- loopback-dən kənara açılmazdan ƏVVƏL parol rotasiya olunmalıdır.
CREATE ROLE report_ro LOGIN PASSWORD 'report_ro_dev'
  NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE report_ro SET default_transaction_read_only = on;
ALTER ROLE report_ro SET statement_timeout = '15s';
ALTER ROLE report_ro SET temp_file_limit = '512MB';
