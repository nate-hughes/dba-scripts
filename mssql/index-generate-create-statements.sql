SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE @DBId                INT          = DB_ID()
       ,@SchemaName          sysname
       ,@TblName             sysname      = N'schema.table'
       ,@TblId               INT
	   ,@OmitHeaps           BIT = 1
	   ,@OmitFillFactor      BIT = 1
	   ,@OmitDropExisting    BIT = 0
	   ,@OmitResumable       BIT = 1
	   ,@OmitConstraints     BIT = 0;

SET @TblId = OBJECT_ID(@TblName);
SET @SchemaName = OBJECT_SCHEMA_NAME(@TblId, @DBId);

SELECT  '[' + DB_NAME() + '].[' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + ']' AS Object
       ,i.name                                                                           AS [Index]
       ,i.type_desc                                                                      AS [Index Type]
       ,ds.name                                                                          AS [Data Space Name]
       ,i.is_primary_key                                                                 AS PK
       ,i.is_unique_constraint                                                           AS AK
	   ,i.is_unique                                                                      AS UNQ
       ,i.fill_factor                                                                    AS [Fill Factor]
       ,STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                            ELSE ', ' + c.name
                    END
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        )                                                                                AS Columns
       ,ISNULL(STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', ' + c.name + '(-)'
                            ELSE ', ' + c.name
                    END
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 1
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        ), '')                                                                           AS [Included Columns]
       ,CASE WHEN i.is_primary_key = 0 AND i.is_unique_constraint = 0 THEN
		'CREATE ' + CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + i.type_desc + ' INDEX [' + i.name COLLATE DATABASE_DEFAULT + ']'
		+ ' ON [' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + '] ('
		+ STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', [' + c.name + '(-)'
                            ELSE ', [' + c.name
                    END + ']'
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        ) + ')' + 
		+ ISNULL(' INCLUDE (' + STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', [' + c.name + '(-)'
                            ELSE ', [' + c.name
                    END + ']'
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 1
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 2, ''
        ) + ')', '')
		+ ' WITH (ONLINE = ON'
		+ CASE WHEN @OmitDropExisting = 1 THEN '' ELSE ', DROP_EXISTING = ON' END
		+ CASE WHEN @OmitFillFactor = 1 THEN '' ELSE ', FILLFACTOR = ' + convert(varchar(50),i.fill_factor) END
		+ CASE WHEN @OmitResumable = 1 THEN '' ELSE ', RESUMABLE = ON' END
		+ ') ON [' + ds.name + ']' + ';' 
	   ELSE
		CASE WHEN @OmitConstraints = 1 THEN ''
		ELSE
		 'ALTER TABLE [' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + '] DROP CONSTRAINT [' + i.name COLLATE DATABASE_DEFAULT + '];'
		 + ' ALTER TABLE [' + @SchemaName + '].[' + OBJECT_NAME(@TblId, @DBId) + '] ADD CONSTRAINT [' + i.name COLLATE DATABASE_DEFAULT + ']'
		 + CASE WHEN i.is_primary_key = 1 THEN ' PRIMARY KEY ' WHEN i.is_unique_constraint = 1 THEN ' UNIQUE ' END
		 + i.type_desc + ' ('
		 + STUFF((
            SELECT    CASE WHEN ic.is_descending_key = 1 THEN ', [' + c.name + '(-)'
                            ELSE ', [' + c.name
                    END + ']'
            FROM  sys.index_columns      ic
                INNER JOIN sys.columns c
                    ON  c.object_id = i.object_id
                    AND c.column_id = ic.column_id
            WHERE ic.object_id = @TblId
            AND   ic.index_id = i.index_id
            AND   ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
         ), 1, 2, ''
         ) + ')'
		 + ' ON [' + ds.name + ']' + ';'
		END
	   END AS [Create Stmt]
FROM    sys.indexes                            i
        INNER JOIN sys.data_spaces             ds
            ON i.data_space_id = ds.data_space_id
        LEFT JOIN sys.dm_db_index_usage_stats AS s
            ON  s.object_id = i.object_id
            AND i.index_id = s.index_id
WHERE   i.object_id = @TblId
AND		((@OmitHeaps = 1 AND i.index_id > 0) OR @OmitHeaps = 0)
AND     i.is_disabled = 0
AND     i.is_hypothetical = 0
ORDER BY CASE WHEN i.index_id = 0 THEN 0
			WHEN i.is_primary_key = 1 THEN 1
			ELSE 2
		END
		,i.name
OPTION (MAXDOP 2);
