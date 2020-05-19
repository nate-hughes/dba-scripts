USE [?];
GO

SET NOCOUNT ON;

DECLARE @TblName NVARCHAR(128) = 'TblName'
       ,@ColList NVARCHAR(MAX) = ''
       ,@sql     NVARCHAR(MAX);

DECLARE @DataTypeNullPct TABLE (DataType NVARCHAR(128), Pct NUMERIC(3, 2), PrecisionLength INT);

DECLARE @IndxCols TABLE (ColumnId INT);

DECLARE @Cols TABLE (
    ColName   NVARCHAR(128)
   ,DataType  NVARCHAR(128)
   ,SparseCol BIT
   ,TargetPct NUMERIC(3, 2)
   ,ColLength SMALLINT
);

INSERT INTO @DataTypeNullPct (DataType, Pct, PrecisionLength)
VALUES ('bit', .98, NULL)
      ,('tinyint', .86, NULL)
      ,('smallint', .76, NULL)
      ,('int', .64, NULL)
      ,('bigint', .52, NULL)
      ,('real', .64, NULL)
      ,('float', .52, NULL)
      ,('smallmoney', .64, NULL)
      ,('money', .52, NULL)
      ,('smalldatetime', .64, NULL)
      ,('datetime', .52, NULL)
      ,('uniqueidentifier', .43, NULL)
      ,('date', .69, NULL)
      ,('varchar', .6, NULL)
      ,('char', .6, NULL)
      ,('nvarchar', .6, NULL)
      ,('nchar', .6, NULL)
      ,('varbinary', .6, NULL)
      ,('binary', .6, NULL)
      ,('xml', .6, NULL)
      ,('hierarchyid', .6, NULL)
      ,('datetime2', .57, 0)
      ,('datetime2', .52, 7)
      ,('time', .69, 0)
      ,('time', .6, 7)
      ,('datetimeoffset', .52, 0)
      ,('datetimeoffset', .49, 7)
      ,('decimal', .6, 1)
      ,('decimal', .42, 38)
      ,('numeric', .6, 1)
      ,('numeric', .42, 38)
      ,('vardecimal', .6, 1)
      ,('vardecimal', .42, 38);

INSERT INTO @IndxCols (ColumnId)
SELECT  c.column_id
FROM    sys.indexes                  i
        INNER JOIN sys.index_columns c
            ON  i.object_id = c.object_id
            AND i.index_id = c.index_id
WHERE   i.object_id = OBJECT_ID(@TblName)
-- clustered, unique or primary key index
AND     (i.index_id = 1 OR  i.is_primary_key = 1 OR i.is_unique_constraint = 1);

INSERT INTO @Cols (ColName, DataType, SparseCol, TargetPct, ColLength)
SELECT  c.name       AS ColName
       ,t.name       AS DataType
       ,c.is_sparse  AS SparseCol
       ,np.Pct       AS TargetPct
       ,c.max_length AS ColLength
FROM    sys.columns                 c
        INNER JOIN sys.types        t
            ON c.system_type_id = t.system_type_id
        INNER JOIN @DataTypeNullPct np
            ON  t.name = np.DataType
            AND c.precision <= ISNULL(np.PrecisionLength, c.precision)
WHERE   c.object_id = OBJECT_ID(@TblName)
-- data types cannot be specified as SPARSE
AND     t.name NOT IN ('geography', 'geometry', 'image', 'ntext', 'text', 'timestamp')
-- data types cannot be specified as SPARSE: user-defined data types 
AND     t.is_user_defined = 0
-- column must be nullable and cannot have the ROWGUIDCOL or IDENTITY properties
AND     c.is_nullable = 1
AND     c.is_rowguidcol = 0
AND     c.is_identity = 0
-- sparse column cannot have the FILESTREAM attribute
AND     c.is_filestream = 0
-- column cannot have a default value
AND     c.default_object_id = 0
-- column cannot be bound to a rule
AND     c.rule_object_id = 0
-- a computed column cannot be marked as SPARSE
AND     c.is_computed = 0
-- cannot be part of a clustered index or a unique primary key index
AND     NOT EXISTS (SELECT  1 FROM  @IndxCols WHERE ColumnId = c.column_id)
-- cannot be used as a partition key of a clustered index or heap
-- cannot be part of a user-defined table type
;

SELECT  @ColList =
    @ColList + N'[' + ColName + N']=' + N'CASE WHEN ' + N'SUM(CASE WHEN ' + N'[' + ColName + N']'
    + N' IS NULL THEN 1 ELSE 0 END' + N')*1.0/COUNT(*)' + N' >= ' + CONVERT(VARCHAR(10), TargetPct)
    + N' THEN ''Y'' ELSE ''N'' END'
    + N','
FROM    @Cols;

SELECT  @sql = N'SELECT ' + LEFT(@ColList, LEN(@ColList) - 1) + N' FROM ' + @TblName;

EXEC sys.sp_executesql @sql;

DBCC SHOWCONTIG(@TblName) WITH TABLERESULTS;

SELECT  ColName
       ,DataType
       ,SparseCol
       ,TargetPct
       ,ColLength
       ,',  ' + ColName + ' = SUM(CASE WHEN ' + ColName + ' IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*)'
FROM    @Cols;
