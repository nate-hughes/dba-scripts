DECLARE @TblName    NVARCHAR(128)
       ,@TblId      INT;

SET @TblName = NULL;

IF @TblName IS NOT NULL
    SET @TblId = OBJECT_ID(@TblName);

DECLARE @IndxCols TABLE (
    TblId              INT
   ,IndxId             INT
   ,Columns            NVARCHAR(4000)
   ,[Included Columns] NVARCHAR(4000)
);

INSERT INTO @IndxCols (TblId, IndxId, Columns, [Included Columns])
SELECT  i.object_id
       ,i.index_id
       ,STUFF((
                  SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                                 ELSE ', ' + c.name
                            END
                  FROM  sys.index_columns      ic
                        INNER JOIN sys.columns c
                            ON  c.object_id = ic.object_id
                            AND c.column_id = ic.column_id
                  WHERE ic.object_id = i.object_id
                  AND   ic.index_id = i.index_id
                  AND   ic.is_included_column = 0
                  ORDER BY ic.key_ordinal
                  FOR XML PATH('')
              ), 1, 2, ''
             ) AS Columns
       ,STUFF((
                  SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                                 ELSE ', ' + c.name
                            END
                  FROM  sys.index_columns      ic
                        INNER JOIN sys.columns c
                            ON  c.object_id = ic.object_id
                            AND c.column_id = ic.column_id
                  WHERE ic.object_id = i.object_id
                  AND   ic.index_id = i.index_id
                  AND   ic.is_included_column = 1
                  ORDER BY ic.key_ordinal
                  FOR XML PATH('')
              ), 1, 2, ''
             ) AS [Included Columns]
FROM    sys.indexes i
WHERE   OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
AND     i.object_id = ISNULL(@TblId, i.object_id);


SELECT  OBJECT_NAME(s.object_id)                          AS TblName
       ,i.name                                            AS IndxName
       ,i.index_id                                        AS IndxId
       ,i.type_desc                                       AS IndxType
       ,i.is_primary_key                                  AS PK
       ,i.is_unique                                       AS AK
       ,d.name                                            AS FileGroup
       ,c.Columns                                         AS IndxColumns
       ,c.[Included Columns]                              AS IncludedColumns
       ,SUM(s.user_seeks + s.user_scans + s.user_lookups) AS TotalReads
       ,SUM(s.user_updates)                               AS TotalWrites
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes      AS i
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
        INNER JOIN sys.data_spaces  AS d
            ON i.data_space_id = d.data_space_id
        INNER JOIN @IndxCols        c
            ON  i.object_id = c.TblId
            AND i.index_id = c.IndxId
WHERE   OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
AND     s.database_id = DB_ID()
AND     s.object_id = ISNULL(@TblId, s.object_id)
AND     i.index_id IN (0, 1) -- heap, ci
GROUP BY OBJECT_NAME(s.object_id)
        ,i.name
        ,i.index_id
        ,i.type_desc
        ,i.is_unique
        ,i.is_primary_key
        ,d.name
        ,c.Columns
        ,c.[Included Columns]
HAVING  SUM(s.user_seeks + s.user_scans + s.user_lookups) + SUM(s.user_updates) > 0
AND     SUM(s.user_updates) = 0
ORDER BY OBJECT_NAME(s.object_id)
        ,i.index_id
        ,TotalWrites DESC
        ,TotalReads DESC
OPTION (RECOMPILE);
