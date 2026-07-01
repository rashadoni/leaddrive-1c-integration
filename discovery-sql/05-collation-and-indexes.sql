-- 05: Collation kənarlaşmaları + ən böyük indekslər (extract planlaması üçün, read-only)
SET NOCOUNT ON;

-- Baza collation-dan fərqlənən sütunlar (JOIN/extract zamanı sürpriz verməsin)
SELECT TOP 50
  t.name  AS table_name,
  c.name  AS column_name,
  c.collation_name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.collation_name IS NOT NULL
  AND c.collation_name <> CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS sysname)
ORDER BY t.name, c.name;

-- Ən böyük 30 indeks (klaster açarları extract-da keyset paginasiyası üçün vacibdir)
SELECT TOP 30
  t.name                                   AS table_name,
  i.name                                   AS index_name,
  i.type_desc,
  SUM(ps.used_page_count) * 8 / 1024       AS used_mb
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
JOIN sys.dm_db_partition_stats ps ON ps.object_id = i.object_id AND ps.index_id = i.index_id
GROUP BY t.name, i.name, i.type_desc
ORDER BY used_mb DESC;

-- _Date_Time üzrə indeksi OLMAYAN sənəd cədvəlləri (extract full-scan riski)
SELECT t.name AS doc_table_without_date_index
FROM sys.tables t
WHERE t.name LIKE N'\_Document[0-9]%' ESCAPE N'\'
  AND t.name NOT LIKE N'%\_VT%' ESCAPE N'\'
  AND EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = t.object_id AND c.name = N'_Date_Time')
  AND NOT EXISTS (
    SELECT 1
    FROM sys.index_columns ic
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE ic.object_id = t.object_id AND c.name = N'_Date_Time' AND ic.key_ordinal = 1
  )
ORDER BY t.name;
