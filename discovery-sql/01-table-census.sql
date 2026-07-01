-- 01: Cədvəl senzusu — sətir sayı + tutduğu yer (read-only)
SET NOCOUNT ON;

;WITH t AS (
  SELECT
    t.object_id,
    t.name                                            AS table_name,
    SUM(ps.row_count)                                 AS row_count,
    SUM(ps.reserved_page_count) * 8 / 1024            AS reserved_mb
  FROM sys.tables t
  JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
  WHERE ps.index_id IN (0, 1)
  GROUP BY t.object_id, t.name
)
SELECT TOP 100 table_name, row_count, reserved_mb
FROM t
ORDER BY reserved_mb DESC;

-- 1C obyekt növü (prefiks) üzrə cəmlər
;WITH t AS (
  SELECT
    t.name                                            AS table_name,
    SUM(ps.row_count)                                 AS row_count,
    SUM(ps.reserved_page_count) * 8 / 1024            AS reserved_mb
  FROM sys.tables t
  JOIN sys.dm_db_partition_stats ps ON ps.object_id = t.object_id
  WHERE ps.index_id IN (0, 1)
  GROUP BY t.name
)
SELECT
  CASE
    WHEN table_name LIKE N'\_Document%\_VT%' ESCAPE N'\' THEN '_Document*_VT* (sənəd tabl.hissələri)'
    WHEN table_name LIKE N'\_DocumentJournal%' ESCAPE N'\' THEN '_DocumentJournal*'
    WHEN table_name LIKE N'\_Document%' ESCAPE N'\'    THEN '_Document* (sənəd başlıqları)'
    WHEN table_name LIKE N'\_Reference%\_VT%' ESCAPE N'\' THEN '_Reference*_VT*'
    WHEN table_name LIKE N'\_Reference%' ESCAPE N'\'   THEN '_Reference* (sorğu kitabçaları)'
    WHEN table_name LIKE N'\_AccumRgT%' ESCAPE N'\'    THEN '_AccumRgT* (yığım registri YEKUNLARI)'
    WHEN table_name LIKE N'\_AccumRg%' ESCAPE N'\'     THEN '_AccumRg* (yığım registri hərəkətləri)'
    WHEN table_name LIKE N'\_InfoRg%' ESCAPE N'\'      THEN '_InfoRg* (məlumat registrləri)'
    WHEN table_name LIKE N'\_AccRg%' ESCAPE N'\'       THEN '_AccRg* (mühasibat registrləri)'
    WHEN table_name LIKE N'\_Enum%' ESCAPE N'\'        THEN '_Enum*'
    WHEN table_name LIKE N'\_Const%' ESCAPE N'\'       THEN '_Const*'
    ELSE 'digər'
  END                                                  AS table_kind,
  COUNT(*)                                             AS tables,
  SUM(row_count)                                       AS total_rows,
  SUM(reserved_mb)                                     AS total_mb
FROM t
GROUP BY
  CASE
    WHEN table_name LIKE N'\_Document%\_VT%' ESCAPE N'\' THEN '_Document*_VT* (sənəd tabl.hissələri)'
    WHEN table_name LIKE N'\_DocumentJournal%' ESCAPE N'\' THEN '_DocumentJournal*'
    WHEN table_name LIKE N'\_Document%' ESCAPE N'\'    THEN '_Document* (sənəd başlıqları)'
    WHEN table_name LIKE N'\_Reference%\_VT%' ESCAPE N'\' THEN '_Reference*_VT*'
    WHEN table_name LIKE N'\_Reference%' ESCAPE N'\'   THEN '_Reference* (sorğu kitabçaları)'
    WHEN table_name LIKE N'\_AccumRgT%' ESCAPE N'\'    THEN '_AccumRgT* (yığım registri YEKUNLARI)'
    WHEN table_name LIKE N'\_AccumRg%' ESCAPE N'\'     THEN '_AccumRg* (yığım registri hərəkətləri)'
    WHEN table_name LIKE N'\_InfoRg%' ESCAPE N'\'      THEN '_InfoRg* (məlumat registrləri)'
    WHEN table_name LIKE N'\_AccRg%' ESCAPE N'\'       THEN '_AccRg* (mühasibat registrləri)'
    WHEN table_name LIKE N'\_Enum%' ESCAPE N'\'        THEN '_Enum*'
    WHEN table_name LIKE N'\_Const%' ESCAPE N'\'       THEN '_Const*'
    ELSE 'digər'
  END
ORDER BY total_mb DESC;
