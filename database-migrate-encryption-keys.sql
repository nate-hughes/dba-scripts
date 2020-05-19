create table #key_tbls (DBName VARCHAR(100), KeyName VARCHAR(100));

declare @sql nvarchar(max) = 'use [?]; insert #key_tbls (DBName, KeyName) select DB_NAME(), name from sys.symmetric_keys where name <> ''##MS_DatabaseMasterKey##'';'

exec sp_MSforeachdb @sql

select DBName, KeyName
	,'use ' + DBName + '; open master key decryption by password = ''password''; alter master key add encryption by service master key; select DBName(); exec SystemConfiguration_GetValue ''ValidationKey'';'
from #key_tbls

/*
open master key decryption by password = 'password'

alter master key add encryption by service master key

exec SystemConfiguration_GetValue 'ValidationKey'
*/
