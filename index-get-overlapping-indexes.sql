--  Create a table variable to hold the core index info
CREATE TABLE #AllIndexes (
   TableID INT NOT NULL,
   SchemaName SYSNAME NOT NULL,
   TableName SYSNAME NOT NULL,
   IndexID INT NULL,
   IndexName NVARCHAR(128) NULL,
   IndexType VARCHAR(12) NOT NULL,
   ConstraintType VARCHAR(11) NOT NULL,
   ObjectType VARCHAR(10) NOT NULL,
   AllColName NVARCHAR(2078) NULL,
   ColName1 NVARCHAR(128) NULL,
   ColName2 NVARCHAR(128) NULL,
   IndexSizeKB BIGINT NULL,
   HasFilter BIT NOT NULL,
   HasIncludedColumn BIT NOT NULL
);
 
DECLARE @ProductVersion NVARCHAR(128);
DECLARE @MajorVersion TINYINT;
DECLARE @loadIndexSQL NVARCHAR(MAX);
 
SET @ProductVersion = CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'));
SET @MajorVersion = CONVERT(TINYINT, LEFT(@ProductVersion, CHARINDEX('.', @ProductVersion) - 1));
 
SET @loadIndexSQL = N'
   INSERT INTO #AllIndexes (TableID, SchemaName, TableName, IndexID, IndexName, IndexType, ConstraintType,
      ObjectType, AllColName, ColName1, ColName2, IndexSizeKB, HasFilter, HasIncludedColumn)
   SELECT o.object_id, -- TableID
      u.[name], -- SchemaName
      o.[name], -- TableName
      i.index_id, -- IndexID
      i.[name], -- IndexName
      CASE i.[type]
         WHEN 0 THEN ''HEAP''
         WHEN 1 THEN ''CL''
         WHEN 2 THEN ''NC''
         WHEN 3 THEN ''XML''
         ELSE ''UNKNOWN''
      END, -- IndexType
      CASE
         WHEN (i.is_primary_key) = 1 THEN ''PK''
         WHEN (i.is_unique) = 1 THEN ''UNQ''
         ELSE ''''
      END, -- ConstraintType
      CASE
         WHEN (i.is_unique_constraint) = 1 OR i.is_primary_key = 1 THEN ''CONSTRAINT''
         WHEN i.type = 0 THEN ''HEAP''
         WHEN i.type = 3 THEN ''XML INDEX''
         ELSE ''INDEX''
      END, -- ObjectType
      (SELECT COALESCE(c1.[name], '''')
         FROM sys.columns AS c1
         INNER JOIN sys.index_columns AS ic1 ON c1.object_id = ic1.object_id
            AND c1.column_id = ic1.column_id
            AND ic1.key_ordinal = 1
         WHERE ic1.object_id = i.object_id
            AND ic1.index_id = i.index_id) +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 2) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 2)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 3) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 3)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 4) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 4)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 5) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 5)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 6) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 6)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 7) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 7)
         END +
         CASE
            WHEN INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 8) IS NULL THEN ''''
            ELSE '', '' + INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.index_id, 8)
         END, -- AllColName
      (SELECT COALESCE(c1.[name], '''')
         FROM sys.columns AS c1
         INNER JOIN sys.index_columns AS ic1 ON c1.[object_id] = ic1.[object_id]
            AND c1.[column_id] = ic1.[column_id]
            AND ic1.[key_ordinal] = 1
         WHERE ic1.[object_id] = i.[object_id]
            AND ic1.[index_id] = i.[index_id]), -- ColName1
         CASE
            WHEN INDEX_COL(''['' + u.name + ''].[''+ o.name + '']'', i.index_id, 2) IS NULL THEN ''''
            ELSE INDEX_COL(''['' + u.[name] + ''].['' + o.[name] + '']'', i.[index_id],2)
         END, -- ColName2
         ps.used_page_count * 8, -- IndexSizeKB' + CHAR(13);        
 
         IF @MajorVersion >= 10
            SET @loadIndexSQL = @loadIndexSQL + 'i.has_filter';
         ELSE
            SET @loadIndexSQL = @loadIndexSQL + '0';
 
         SET @loadIndexSQL = @loadIndexSQL + ', -- HasFilter' + CHAR(13);
 
         IF @MajorVersion >= 9
            SET @loadIndexSQL = @loadIndexSQL + 'CASE WHEN (SELECT COUNT(*) FROM sys.index_columns ic WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1) >= 1 THEN 1 ELSE 0 END';
         ELSE
            SET @loadIndexSQL = @loadIndexSQL + '0';
 
         SET @loadIndexSQL = @loadIndexSQL + ' -- HasIncludedColumn
   FROM sys.objects o WITH (NOLOCK)
      INNER JOIN sys.schemas u WITH (NOLOCK) ON o.schema_id = u.schema_id
      LEFT OUTER JOIN sys.indexes i WITH (NOLOCK) ON o.object_id = i.object_id
      LEFT OUTER JOIN sys.dm_db_partition_stats ps WITH (NOLOCK) ON ps.[object_id] = i.[object_id] AND ps.[index_id] = i.[index_id]
   WHERE o.[type] = ''U''
      AND o.[name] NOT IN (''dtproperties'')
      AND i.[name] NOT LIKE ''_WA_Sys_%'';
';

EXEC sp_executesql @loadIndexSQL;
 
-----------
--SELECT 'Listing Possible Redundant Index keys' AS [Comments];
 
SELECT DISTINCT i.SchemaName, i.TableName, i.IndexName,i.IndexType, i.ConstraintType, i.AllColName, i.IndexSizeKB, i.HasFilter, i.HasIncludedColumn
   FROM #AllIndexes AS i
   JOIN #AllIndexes AS i2 ON i.TableID = i2.TableID
      AND i.ColName1 = i2.ColName1
      AND i.IndexName <> i2.IndexName
      AND i.IndexType <> 'XML'
   ORDER BY i.SchemaName, i.TableName, i.AllColName;
   
DROP TABLE #AllIndexes;