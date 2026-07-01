-- 00: Server / baza pasportu (read-only)
SET NOCOUNT ON;

SELECT
  @@VERSION                                   AS sql_version,
  SERVERPROPERTY('Edition')                   AS edition,
  SERVERPROPERTY('ProductLevel')              AS product_level,
  SERVERPROPERTY('Collation')                 AS server_collation;

SELECT
  DB_NAME()                                   AS db_name,
  d.compatibility_level,
  d.collation_name,
  d.recovery_model_desc,
  d.is_read_only
FROM sys.databases d
WHERE d.database_id = DB_ID();

-- Fayl ölçüləri (MB)
SELECT
  mf.name              AS logical_name,
  mf.type_desc,
  mf.size * 8 / 1024   AS size_mb,
  mf.physical_name
FROM sys.master_files mf
WHERE mf.database_id = DB_ID()
ORDER BY mf.type_desc, mf.name;
