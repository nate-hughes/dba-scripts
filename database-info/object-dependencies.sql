
SELECT  OBJECT_SCHEMA_NAME(d.referencing_id) AS srcschema -- Schema in which the referencing entity belongs.
       ,OBJECT_NAME(d.referencing_id)        AS srcname -- Name of the referencing entity.
       ,srcc.name                            AS srccolumn -- Column name when the referencing entity is a column.
       ,d.referenced_server_name             AS tgtserver -- Name of the server of the referenced entity.
       ,d.referenced_database_name           AS tgtdatabase -- Name of the database of the referenced entity.
       ,d.referenced_schema_name             AS tgtschema -- Schema in which the referenced entity belongs.
       ,d.referenced_entity_name             AS tgtname -- Name of the referenced entity. Is not nullable.
       ,srct.name                            AS tgtcolumn -- Name of the referenced column when the referencing entity is a column.
FROM    sys.sql_expression_dependencies d
        LEFT OUTER JOIN sys.columns     srcc
            ON  d.referencing_id = srcc.object_id
            AND d.referencing_minor_id = srcc.column_id
        LEFT OUTER JOIN sys.columns     srct
            ON  d.referenced_id = srct.object_id
            AND d.referenced_minor_id = srct.column_id;


SELECT  e.referenced_server_name   AS objserver
       ,e.referenced_database_name AS objdatabase
       ,e.referenced_schema_name   AS objschema
       ,e.referenced_entity_name   AS objname
       ,e.referenced_minor_name    AS objcolumn
       ,o.type_desc                AS objtype
       ,e.is_selected              AS objselected -- 1 = The object or column is selected.
       ,e.is_select_all            AS objselectstar -- 1 = The object is used in a SELECT * clause (object-level only).
       ,e.is_updated               AS objupdated -- 1 = The object or column is modified.
       ,e.is_all_columns_found     AS objcolumnfound -- 0 = Column dependencies for the object could not be found.
FROM    sys.dm_sql_referenced_entities('dbo.P_OSAR_SAVE_Fin_File', 'OBJECT') e
        LEFT OUTER JOIN sys.objects                                          o
            ON e.referenced_id = o.object_id;


SELECT  e.referencing_schema_name AS objschema
       ,e.referencing_entity_name AS objname
       ,o.type_desc               AS objtype
FROM    sys.dm_sql_referencing_entities('dbo.T_OSAR_REPORT_SIZES', 'OBJECT') e
        LEFT OUTER JOIN sys.objects                                          o
            ON e.referencing_id = o.object_id;
