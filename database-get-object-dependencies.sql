
-- FIND USER-DEFINED OBJECT DEPENDENCIES
DECLARE @ObjName VARCHAR(128) = 'schema.object';

-- FIND WHAT OBJECT REFERENCES
SELECT  OBJECT_SCHEMA_NAME(d.referencing_id) AS srcschema -- Schema in which the referencing entity belongs.
       ,OBJECT_NAME(d.referencing_id)        AS srcname -- Name of the referencing entity.
	   ,srco.type_desc						 AS srctype -- Type of the referencing entity.
       ,srcc.name                            AS srccolumn -- Column name when the referencing entity is a column.
       ,d.referenced_server_name             AS tgtserver -- Name of the server of the referenced entity.
       ,d.referenced_database_name           AS tgtdatabase -- Name of the database of the referenced entity.
       ,d.referenced_schema_name             AS tgtschema -- Schema in which the referenced entity belongs.
       ,d.referenced_entity_name             AS tgtname -- Name of the referenced entity. Is not nullable.
	   ,tgto.type_desc						 AS tgttype -- Type of the referenced entity. Only known if in the same database.
       ,srct.name                            AS tgtcolumn -- Name of the referenced column when the referencing entity is a column and is in the same database.
FROM    sys.sql_expression_dependencies d
		JOIN sys.objects srco ON d.referencing_id = srco.object_id
        LEFT OUTER JOIN sys.columns     srcc
            ON  d.referencing_id = srcc.object_id
            AND d.referencing_minor_id = srcc.column_id
        LEFT OUTER JOIN sys.columns     srct
            ON  d.referenced_id = srct.object_id
            AND d.referenced_minor_id = srct.column_id
		LEFT OUTER JOIN sys.objects tgto ON d.referenced_id = tgto.object_id
WHERE	@ObjName IS NULL
OR		OBJECT_SCHEMA_NAME(d.referencing_id) + '.' + OBJECT_NAME(d.referencing_id) = @ObjName;

EXEC sp_depends @ObjName;
EXEC sp_MSdependencies @ObjName, NULL, 1053183;

-- FIND WHAT REFERENCES OBJECT
SELECT  e.referencing_schema_name AS objschema
       ,e.referencing_entity_name AS objname
       ,o.type_desc               AS objtype
FROM    sys.dm_sql_referencing_entities(@ObjName, 'OBJECT') e
        LEFT OUTER JOIN sys.objects o
            ON e.referencing_id = o.object_id;

EXEC sp_MSdependencies @ObjName, NULL, 1315327;

WITH ref_inputs (tblename, objschema, objname, objtype)
AS (
    SELECT  e.referencing_schema_name  AS objschema
			,e.referencing_entity_name AS objname
			,o.type_desc               AS objtype
    FROM    sys.dm_sql_referencing_entities(@ObjName, 'OBJECT') e
            JOIN sys.objects o ON e.referencing_id = o.object_id
) 
SELECT	ref_inputs.objschema+'.'+ref_inputs.objname first_level_dep
		,ref_inputs.objtype AS first_level_dep_objtype
		,e2.referencing_schema_name AS second_level_dep_objschema
		,e2.referencing_entity_name AS second_level_dep_objname 
		,o2.type_desc               AS second_level_dep_objtype
FROM	ref_inputs
		OUTER APPLY sys.dm_sql_referencing_entities(ref_inputs.objschema+'.'+ref_inputs.objname, 'OBJECT') e2 
		LEFT JOIN sys.objects o2 ON e2.referencing_id = o2.object_id
ORDER BY first_level_dep
		,second_level_dep_objschema
		,second_level_dep_objname;

