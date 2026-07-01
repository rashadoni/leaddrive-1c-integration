# Windows test maşını üçün native quraşdırma (Docker yoxdursa)

> Default yol `docker-compose.yml`-dir (Linux və ya Docker Desktop olan Windows).
> Bu runbook — Docker qadağan/mümkünsüz olan Windows Server üçün fallback.

## 1. SQL Server 2019 Developer Edition (kopya üçün)

1. Microsoft saytından **SQL Server 2019 Developer** yüklə (pulsuz; yalnız dev/test istifadəsi
   üçün lisenziyalıdır — PoC məhz budur. **İstifadəçilərə hesabat açmaq olmaz** — o artıq
   prod istifadə sayılır).
2. Instance: default, Mixed Mode auth; `sa` parolu güclü.
3. `.bak` bərpası (əvvəlcə yer hesabla):
   ```sql
   RESTORE FILELISTONLY FROM DISK = N'D:\backup\base.bak';      -- MDF+LDF ölçülərinə bax
   RESTORE DATABASE pharma_copy FROM DISK = N'D:\backup\base.bak'
     WITH MOVE N'<LogicalDataName>' TO N'E:\data\pharma_copy.mdf',
          MOVE N'<LogicalLogName>'  TO N'E:\data\pharma_copy_log.ldf',
          STATS = 5;
   ALTER DATABASE pharma_copy SET RECOVERY SIMPLE;
   DBCC SHRINKFILE (N'<LogicalLogName>', 1024);                  -- log-u kiçilt
   ALTER DATABASE pharma_copy SET READ_ONLY;                     -- təsadüfi yazıya qarşı
   ```
4. Read-only login yarat: `CREATE LOGIN etl_ro WITH PASSWORD='...'; USE pharma_copy;
   CREATE USER etl_ro FOR LOGIN etl_ro; EXEC sp_addrolemember 'db_datareader','etl_ro';`

## 2. PostgreSQL 16 (DWH)

1. EDB installer ilə PostgreSQL 16 qur (port 5432, data ayrıca diskdə).
2. `psql -U postgres` ilə bu repodakı DDL-ləri sırayla işə sal:
   `dwh/ddl/000-init-databases.sql` → `001-schema.sql` → `002-runlog.sql`.
3. `postgresql.conf` minimal tuning: `shared_buffers = RAM/4`, `work_mem = 64MB`,
   `maintenance_work_mem = 1GB`, `max_wal_size = 4GB`.

## 3. Node.js + ETL

1. Node.js 20 LTS (MSI) qur.
2. Bu repodan `etl/` qovluğunu maşına köçür; `npm install`; `.env` doldur.
3. Yoxlama: `npx tsx src/cli.ts discover` → `out/discovery/` faylları yaranmalıdır.

## 4. Metabase (jar, servis kimi)

1. Java 21 (Temurin) qur; `metabase.jar` yüklə.
2. `MB_DB_TYPE=postgres MB_DB_HOST=localhost MB_DB_DBNAME=metabase_app MB_DB_USER=dwh ...`
   environment ilə `java -jar metabase.jar` — http://localhost:3000.
3. Servisləşdirmə: **NSSM** (`nssm install metabase ...`, `nssm install pharma-etl ...`) —
   restart-da avtomatik qalxır, log faylları `nssm set <svc> AppStdout/AppStderr` ilə.

## 5. Firewall qeydləri

- Daxili: 5432 (PG) və 3000 (Metabase) yalnız lazımi seqmentə açıq.
- Xarici: NL modulu üçün YALNIZ outbound 443 → api.anthropic.com (Gate 1 qərarı C4).
- SMTP relay: questionnaire C5 cavabına görə.
