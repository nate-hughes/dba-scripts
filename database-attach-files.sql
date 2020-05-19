USE master;
GO

EXEC sys.sp_attach_db @dbname = 'DBName'
	,@filename1 = N'H:\SQL\Data\DBName.mdf'
	,@filename2 = N'I:\SQL\Log\DBName_log.ldf'
	,@filename3 = N'H:\SQL\Data\DBName_2.ndf'
	,@filename4 = N'G:\SQL\Data\DBName_indexes.ndf'
GO
ALTER AUTHORIZATION ON DATABASE::[DBName] TO [sa];
GO
