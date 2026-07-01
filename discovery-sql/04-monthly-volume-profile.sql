-- 04: Ay-ay sənəd həcmi profili (dinamik SQL, read-only).
-- Məqsəd: 30k/gün satış sənədinin hansı _DocumentNNN cədvəlində olduğunu HƏCMLƏ tapmaq —
-- metadata xəritəsi hazır olana qədər ən etibarlı işarə.
-- Qeyd: kopyada işlədilir; NOLOCK yalnız ehtiyat üçündür.
SET NOCOUNT ON;

DECLARE @offset int = 0;
IF OBJECT_ID(N'dbo._YearOffset', 'U') IS NOT NULL
  SELECT TOP 1 @offset = [Offset] FROM dbo._YearOffset;

IF OBJECT_ID('tempdb..#vol') IS NOT NULL DROP TABLE #vol;
CREATE TABLE #vol (table_name sysname, ym char(7), doc_count int);

DECLARE @t sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT t.name
  FROM sys.tables t
  WHERE t.name LIKE N'\_Document[0-9]%' ESCAPE N'\'
    AND t.name NOT LIKE N'%\_VT%' ESCAPE N'\'
    AND t.name NOT LIKE N'%Chng%'
    AND EXISTS (SELECT 1 FROM sys.columns c1 WHERE c1.object_id = t.object_id AND c1.name = N'_Date_Time')
    AND EXISTS (SELECT 1 FROM sys.columns c2 WHERE c2.object_id = t.object_id AND c2.name = N'_Posted');

OPEN c;
FETCH NEXT FROM c INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql =
    N'INSERT INTO #vol ' +
    N'SELECT @tname, CONVERT(char(7), DATEADD(year, -@off, _Date_Time), 120), COUNT(*) ' +
    N'FROM ' + QUOTENAME(@t) + N' WITH (NOLOCK) ' +
    N'WHERE _Posted = 0x01 ' +
    N'GROUP BY CONVERT(char(7), DATEADD(year, -@off, _Date_Time), 120)';
  EXEC sp_executesql @sql, N'@off int, @tname sysname', @off = @offset, @tname = @t;
  FETCH NEXT FROM c INTO @t;
END
CLOSE c; DEALLOCATE c;

-- Son 3 ayın ən aktiv sənəd cədvəlləri (satış sənədi burada zirvədə olacaq)
SELECT TOP 30 table_name, SUM(doc_count) AS docs_last_3m
FROM #vol
WHERE ym >= CONVERT(char(7), DATEADD(month, -3, GETDATE()), 120)
GROUP BY table_name
ORDER BY docs_last_3m DESC;

-- Tam ay-ay profil (Gate 1 hesabatına əlavə olunur)
SELECT table_name, ym, doc_count
FROM #vol
ORDER BY table_name, ym;
