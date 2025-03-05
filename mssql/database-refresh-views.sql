DECLARE @l_sql NVARCHAR(4000);

SET @l_sql =
'USE [?];'
+ '
SELECT ''USE '' + DB_NAME() + '';'';
SELECT ''GO''
SELECT DISTINCT ''EXEC sp_refreshview '' + schema_name(so.schema_id) + ''.'' + name + '';
GO''   
FROM sys.objects AS so   
INNER JOIN sys.sql_expression_dependencies AS sed   
    ON so.object_id = sed.referencing_id   
WHERE so.type = ''V''';

EXEC sp_msforeachdb @l_sql;
