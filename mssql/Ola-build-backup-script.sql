
DECLARE	@SQL NVARCHAR(4000)
		,@DefaultBackup NVARCHAR(512);

EXEC master.dbo.xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='BackupDirectory',
    @value=@DefaultBackup OUTPUT;

SELECT	'EXECUTE [dbo].[DatabaseBackup] 
@Databases = ''' + name + ''',
@Directory = ''' + @DefaultBackup + ''',
@BackupType = ''FULL'',
@Compress = ''Y'',
@LogToTable = ''Y'';'
FROM sys.databases
WHERE database_id > 4