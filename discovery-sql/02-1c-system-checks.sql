-- 02: 1C sistem yoxlamaları — ETL üçün 3 kritik sual (read-only)
SET NOCOUNT ON;

-- (1) _YearOffset: 2000-dirsə bütün tarixlər +2000 il saxlanır (4026-cı il kimi).
--     Extract SQL-də DATEADD(year, -offset, _Date_Time) tətbiq olunmalıdır.
IF OBJECT_ID(N'dbo._YearOffset', 'U') IS NOT NULL
  SELECT 'YearOffset' AS check_name, CAST([Offset] AS nvarchar(20)) AS value FROM dbo._YearOffset;
ELSE
  SELECT 'YearOffset' AS check_name, N'TABLE MISSING (offset=0 qəbul et)' AS value;

-- (2) Params/DBNames: metadata UUID ↔ cədvəl nömrəsi xəritəsinin mənbəyi
--     (decoder: etl/src/decode-dbnames.ts)
IF OBJECT_ID(N'dbo.Params', 'U') IS NOT NULL
  SELECT 'Params:' + FileName AS check_name,
         CAST(DATALENGTH(BinaryData) AS nvarchar(20)) + N' bytes' AS value
  FROM dbo.Params
  WHERE FileName IN (N'DBNames', N'DBSchema');
ELSE
  SELECT 'Params' AS check_name, N'TABLE MISSING' AS value;

-- (3) _Version (rowversion) sütunları: varsa — incremental ETL üçün dəqiq cursor
--     (backdated düzəlişləri də tutur)
SELECT
  'VersionColumns' AS check_name,
  CAST(COUNT(*) AS nvarchar(20)) + N' tables with _Version' AS value
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
WHERE c.name = N'_Version';

-- _Version tipinin yoxlanışı (timestamp/rowversion olmalıdır) — ilk 10 nümunə
SELECT TOP 10
  t.name AS table_name,
  ty.name AS version_type
FROM sys.columns c
JOIN sys.tables t  ON t.object_id = c.object_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
WHERE c.name = N'_Version'
ORDER BY t.name;
