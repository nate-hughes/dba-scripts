DECLARE @TableName AS VARCHAR(250) = '<TblName>';

-- FOREIGN KEYS ON TARGET TABLE
SELECT  fk.name                                                      AS ForeignKey
       ,CASE WHEN fk.is_not_for_replication = 0 THEN 'No'
             ELSE 'yes'
        END                                                          AS IsNotForReplication
       ,OBJECT_NAME(fk.parent_object_id)                             AS TableName
       ,COL_NAME(fkc.parent_object_id, fkc.parent_column_id)         AS ColumnName
       ,OBJECT_NAME(fk.referenced_object_id)                         AS ReferenceTableName
       ,COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferenceColumnName
FROM    sys.foreign_keys                   AS fk
        INNER JOIN sys.foreign_key_columns AS fkc
            ON fk.object_id = fkc.constraint_object_id
WHERE	fkc.parent_object_id = OBJECT_ID(@TableName)
ORDER BY IsNotForReplication;

-- FOREIGN KEYS REFERENCING TARGET TABLE
SELECT  fk.name                                                      AS ForeignKey
       ,CASE WHEN fk.is_not_for_replication = 0 THEN 'No'
             ELSE 'yes'
        END                                                          AS IsNotForReplication
       ,OBJECT_NAME(fk.parent_object_id)                             AS TableName
       ,COL_NAME(fkc.parent_object_id, fkc.parent_column_id)         AS ColumnName
       ,OBJECT_NAME(fk.referenced_object_id)                         AS ReferenceTableName
       ,COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferenceColumnName
FROM    sys.foreign_keys                   AS fk
        INNER JOIN sys.foreign_key_columns AS fkc
            ON fk.object_id = fkc.constraint_object_id
WHERE	fkc.referenced_object_id = OBJECT_ID(@TableName)
ORDER BY IsNotForReplication;