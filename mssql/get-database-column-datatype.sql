USE [?];
GO

SELECT	object_name(c.object_id) as TableName
		,c.name as ColumnName
		,upper(t.name) as Datatype
		,case when c.max_length = -1 then 'max' else convert(varchar(10),c.max_length) end as max_length
from	sys.columns c
		join sys.types t on c.system_type_id = t.system_type_id
		join sys.tables b on c.object_id = b.object_id
where	t.name = 'nvarchar'
and		schema_name(b.schema_id) = 'dbo'
order by 1, c.column_id

