/*
Purpose:
    Identify possible overlapping indexes (based on ordered key columns) in the current database.

What this script flags:
    1. Exact Key Match - two indexes on the same table have the same ordered key columns

    2. Left-Based Key Overlap - one index's ordered key columns are the left-based prefix of another index

        Example:
            IX_A: (CustomerID)
            IX_B: (CustomerID, CreatedDate)

        IX_A may overlap with IX_B, depending on included columns, filters, uniqueness, and workload.

Important notes:
    - Filtered indexes are only compared to indexes with the same filter definition
    - Included columns are displayed but are not used alone to determine overlap
    - Unique indexes, primary keys, and unique constraints are flagged because they require extra caution
    - Disabled and hypothetical indexes are shown but should be interpreted differently
*/

SET NOCOUNT ON;

DROP TABLE IF EXISTS #IndexInfo;
CREATE TABLE #IndexInfo (
    ObjectID              INT           NOT NULL
    ,IndexID              INT           NOT NULL
    ,SchemaName           SYSNAME       NOT NULL
    ,TableName            SYSNAME       NOT NULL
    ,IndexName            SYSNAME       NOT NULL
    ,IndexType            NVARCHAR(60)  NOT NULL
    ,KeyColumns           NVARCHAR(MAX) NOT NULL
    ,KeyColumnsForCompare NVARCHAR(MAX) NOT NULL
    ,KeyColumnCount       INT           NOT NULL
    ,IncludedColumns      NVARCHAR(MAX) NULL
    ,FilterDefinition     NVARCHAR(MAX) NULL
    ,IsUnique             BIT           NOT NULL
    ,IsPrimaryKey         BIT           NOT NULL
    ,IsUniqueConstraint   BIT           NOT NULL
    ,IsFiltered           BIT           NOT NULL
    ,IsDisabled           BIT           NOT NULL
    ,IsHypothetical       BIT           NOT NULL
    ,IndexSizeKB          BIGINT        NULL
);

WITH IndexSize AS (
    SELECT  object_id
            ,index_id
            ,SUM(used_page_count) * 8 AS IndexSizeKB
    FROM sys.dm_db_partition_stats
    GROUP BY object_id
            ,index_id
),
KeyColumns AS (
    SELECT  ic.object_id
            ,ic.index_id
            ,COUNT(*) AS KeyColumnCount
            ,STRING_AGG(
                CONVERT(NVARCHAR(MAX),
                    QUOTENAME(c.name) + 
                    CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
                ),
                ', '
            ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
            ,STRING_AGG(
                CONVERT(NVARCHAR(MAX),
                    QUOTENAME(c.name) + 
                    CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
                ),
                '|'
            ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumnsForCompare
    FROM sys.index_columns ic
        JOIN sys.columns c
            ON ic.object_id = c.object_id
            AND ic.column_id = c.column_id
    WHERE ic.key_ordinal > 0
      AND ic.is_included_column = 0
    GROUP BY ic.object_id
            ,ic.index_id
),
IncludedColumns AS (
    SELECT  ic.object_id
            ,ic.index_id
            ,STRING_AGG(CONVERT(NVARCHAR(MAX), QUOTENAME(c.name)), ', ')
                WITHIN GROUP (ORDER BY c.column_id) AS IncludedColumns
    FROM sys.index_columns ic
        JOIN sys.columns c
            ON ic.object_id = c.object_id
            AND ic.column_id = c.column_id
    WHERE ic.is_included_column = 1
    GROUP BY ic.object_id
            ,ic.index_id
)

INSERT #IndexInfo (
    ObjectID
    ,IndexID
    ,SchemaName
    ,TableName
    ,IndexName
    ,IndexType
    ,KeyColumns
    ,KeyColumnsForCompare
    ,KeyColumnCount
    ,IncludedColumns
    ,FilterDefinition
    ,IsUnique
    ,IsPrimaryKey
    ,IsUniqueConstraint
    ,IsFiltered
    ,IsDisabled
    ,IsHypothetical
    ,IndexSizeKB
)
SELECT  o.object_id,
        i.index_id,
        s.name AS SchemaName,
        o.name AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        kc.KeyColumns,
        kc.KeyColumnsForCompare,
        kc.KeyColumnCount,
        inc.IncludedColumns,
        i.filter_definition,
        i.is_unique,
        i.is_primary_key,
        i.is_unique_constraint,
        i.has_filter,
        i.is_disabled,
        i.is_hypothetical,
        sz.IndexSizeKB
FROM sys.indexes i
    JOIN sys.objects o 
        ON i.object_id = o.object_id
    JOIN sys.schemas s
        ON o.schema_id = s.schema_id
    JOIN KeyColumns kc
        ON i.object_id = kc.object_id
        AND i.index_id = kc.index_id
    LEFT JOIN IncludedColumns inc
        ON i.object_id = inc.object_id
        AND i.index_id = inc.index_id
    LEFT JOIN IndexSize sz
        ON i.object_id = sz.object_id
        AND i.index_id = sz.index_id
WHERE o.type = 'U'
  AND o.is_ms_shipped = 0
  AND i.index_id > 0
  AND i.type IN (1,2) -- clustered and nonclustered rowstore indexes only
  AND i.name IS NOT NULL;

SELECT i.SchemaName AS SchName
    ,i.TableName AS TblName
    ,i.IndexName AS IndxName
    ,i.IndexType AS IndxType
    ,i.KeyColumns AS KeyCols
    ,i.IncludedColumns AS IncludedCols
    ,i.FilterDefinition AS FilterDef
    ,i.IndexSizeKB AS IndxSizeKB
    ,i.IsUnique
    ,i.IsPrimaryKey
    ,i.IsUniqueConstraint
    ,i.IsDisabled
    ,i.IsHypothetical
    ,i2.IndexName AS OverlappingIndx
    ,i2.IndexType AS OverlappingIndxType
    ,i2.KeyColumns AS OverlappingKeyCols
    ,i2.IncludedColumns AS OverlappingIncludedCols
    ,i2.FilterDefinition AS OverlappingFilterDef
    ,i2.IndexSizeKB AS OverlappingIndxSizeKB
    ,i2.IsUnique AS OverlappingIsUnique
    ,i2.IsPrimaryKey AS OverlappingIsPrimaryKey
    ,i2.IsUniqueConstraint AS OverlappingIsUniqueConstraint
    ,i2.IsDisabled AS OverlappingIsDisabled
    ,i2.IsHypothetical AS OverlappingIsHypothetical
    ,CASE WHEN i.KeyColumnsForCompare = i2.KeyColumnsForCompare THEN 'Exact Key Match'
        ELSE 'Left-Based Key Overlap'
    END AS OverlapType
    ,CASE WHEN i.IsDisabled = 1 OR i2.IsDisabled = 1 THEN 'Disabled index involved'
        WHEN i.IsHypothetical = 1 OR i2.IsHypothetical = 1 THEN 'Hypothetical index involved'
        WHEN i.IsPrimaryKey = 1
            AND i2.IsPrimaryKey = 0
            AND i.KeyColumnsForCompare = i2.KeyColumnsForCompare
            THEN 'PK may cover overlapping index'
        WHEN i.IsUniqueConstraint = 1
            AND i2.IsUniqueConstraint = 0
            AND i.KeyColumnsForCompare = i2.KeyColumnsForCompare
            THEN 'Unique constraint may cover overlapping index'
        WHEN i.IsUnique = 1
            AND i2.IsUnique = 0
            AND i.KeyColumnsForCompare = i2.KeyColumnsForCompare
            THEN 'Unique index may cover overlapping non-unique index'
        WHEN i.IsUnique = 1
            AND i2.IsUnique = 0
            AND i.KeyColumnsForCompare <> i2.KeyColumnsForCompare
            THEN 'Unique index with left-based overlap - review carefully'
        WHEN i.IsUnique <> i2.IsUnique
            THEN 'Uniqueness differs - review carefully'
        WHEN i.IsPrimaryKey = 1
            OR i.IsUniqueConstraint = 1
            OR i2.IsPrimaryKey = 1
            OR i2.IsUniqueConstraint = 1
            THEN 'Constraint-backed index involved - review carefully'
        ELSE 'Review candidate'
    END AS ReviewNote
FROM #IndexInfo i
    JOIN #IndexInfo i2
        ON i.ObjectID = i2.ObjectID
        AND i.IndexID <> i2.IndexID
        AND i.KeyColumnCount <= i2.KeyColumnCount
        AND (
                i.KeyColumnsForCompare = i2.KeyColumnsForCompare
                OR i2.KeyColumnsForCompare LIKE i.KeyColumnsForCompare + '|%'
            )
        AND ISNULL(i.FilterDefinition, '') = ISNULL(i2.FilterDefinition, '')
        AND (
                i.IsUnique = i2.IsUnique
                OR i.IsUnique = 1
            )
WHERE NOT (
            i.KeyColumnsForCompare = i2.KeyColumnsForCompare
            AND i.IsUnique = i2.IsUnique
            AND i.IndexID > i2.IndexID
          )
ORDER BY i.SchemaName
        ,i.TableName
        ,i.KeyColumns
        ,i.IndexName
        ,i2.IndexName;

DROP TABLE IF EXISTS #IndexInfo;