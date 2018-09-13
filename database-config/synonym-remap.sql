USE [?];

DECLARE @l_SQL      NVARCHAR(MAX)  = ''
       ,@l_TargetDB NVARCHAR(1035) = '%MCM_ETL%';

SELECT  @l_SQL += N'DROP SYNONYM dbo.' + name + N'; CREATE SYNONYM dbo.' + name + N' FOR RPRMBSSQLVS2.'
                  + base_object_name + N';'
FROM    sys.synonyms
WHERE   base_object_name LIKE @l_TargetDB;

EXEC sys.sp_executesql @l_SQL;

