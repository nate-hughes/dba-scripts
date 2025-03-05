-- https://dba.stackexchange.com/questions/25531/how-can-i-get-the-actual-data-size-per-row-in-a-sql-server-table

declare @table nvarchar(128)
declare @idcol nvarchar(128)
declare @sql nvarchar(max)

--initialize those two values
set @table = 'TblName'
set @idcol = 'ColName'

set @sql = 'select ' + @idcol +' , (0'

--rowsize = number of bytes
select @sql = @sql + ' + isnull(datalength([' + name + ']), 1)' 
        from sys.columns where object_id = object_id(@table)
set @sql = @sql + ') as rowsize from ' + @table + ' order by rowsize desc'
    
PRINT @sql
    
exec (@sql)
