-- 03: Sənəd / registr inventarı — metadata xəritəsindən ƏVVƏL pattern-əsaslı ilkin xəritə
-- (read-only)
SET NOCOUNT ON;

-- Sənəd başlıq cədvəlləri: _DocumentNNN (postable olanlar _Posted sütunu daşıyır)
SELECT
  t.name                                               AS table_name,
  SUM(ps.row_count)                                    AS row_count,
  MAX(CASE WHEN c.name = N'_Posted'    THEN 1 ELSE 0 END) AS has_posted,
  MAX(CASE WHEN c.name = N'_Date_Time' THEN 1 ELSE 0 END) AS has_datetime,
  MAX(CASE WHEN c.name = N'_Number'    THEN 1 ELSE 0 END) AS has_number,
  MAX(CASE WHEN c.name = N'_Version'   THEN 1 ELSE 0 END) AS has_version
FROM sys.tables t
JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id AND ps.index_id IN (0,1)
LEFT JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name LIKE N'\_Document[0-9]%' ESCAPE N'\'
  AND t.name NOT LIKE N'%\_VT%'   ESCAPE N'\'
  AND t.name NOT LIKE N'%Chng%'
GROUP BY t.name
ORDER BY SUM(ps.row_count) DESC;

-- Yığım registrləri (hərəkətlər): stok / partiya / satış registrlərinin namizədləri.
-- Dimension sütunlarının sayı (_Fld*RRef) registrin "enini" göstərir.
SELECT
  t.name                                               AS table_name,
  SUM(ps.row_count)                                    AS row_count,
  MAX(CASE WHEN c.name = N'_Period'       THEN 1 ELSE 0 END) AS has_period,
  MAX(CASE WHEN c.name = N'_RecorderTRef' THEN 1 ELSE 0 END) AS has_recorder_t,
  MAX(CASE WHEN c.name = N'_RecorderRRef' THEN 1 ELSE 0 END) AS has_recorder_r,
  MAX(CASE WHEN c.name = N'_Active'       THEN 1 ELSE 0 END) AS has_active,
  MAX(CASE WHEN c.name = N'_RecordKind'   THEN 1 ELSE 0 END) AS has_recordkind -- gəlir/məxaric reg-i deməkdir
FROM sys.tables t
JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id AND ps.index_id IN (0,1)
LEFT JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name LIKE N'\_AccumRg[0-9]%' ESCAPE N'\'
GROUP BY t.name
ORDER BY SUM(ps.row_count) DESC;

-- Sorğu kitabçası namizədləri (Nomenklatura ~15k, Kontragentlər ~1.5k+600 gözlənilir —
-- sətir sayı kitabçanı tanımağa kömək edir)
SELECT
  t.name                                               AS table_name,
  SUM(ps.row_count)                                    AS row_count,
  MAX(CASE WHEN c.name = N'_Code'        THEN 1 ELSE 0 END) AS has_code,
  MAX(CASE WHEN c.name = N'_Description' THEN 1 ELSE 0 END) AS has_description,
  MAX(CASE WHEN c.name = N'_ParentIDRRef' THEN 1 ELSE 0 END) AS has_hierarchy,
  MAX(CASE WHEN c.name = N'_Marked'      THEN 1 ELSE 0 END) AS has_marked
FROM sys.tables t
JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id AND ps.index_id IN (0,1)
LEFT JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name LIKE N'\_Reference[0-9]%' ESCAPE N'\'
  AND t.name NOT LIKE N'%\_VT%' ESCAPE N'\'
GROUP BY t.name
HAVING SUM(ps.row_count) BETWEEN 100 AND 100000   -- kitabça ölçüsü diapazonu
ORDER BY SUM(ps.row_count) DESC;
