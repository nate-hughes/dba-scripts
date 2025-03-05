--ALTER DATABASE MyDatabase SET OFFLINE;

----move log file to E drive manually and attach from new location

--ALTER DATABASE MyDatabase

--      MODIFY FILE (

--            NAME='MyDatabase_Log',

--            FILENAME='E:\LogFiles\MyDatabase_Log.ldf');

--ALTER DATABASE MyDatabase SET ONLINE;

USE master;
GO
SET NOCOUNT ON;
GO

DECLARE @OverrideDB sysname = 'DBName'
		,@ServerName sysname = @@SERVERNAME
		,@TargetFile varchar(200) = 'LogicalFileName'
		,@NewFilePath varchar(200) = 'Path+FileName';

-- create offline statement
SELECT  'ALTER DATABASE ' + name + ' SET OFFLINE;' AS OfflineDatabase
FROM    sys.databases
WHERE   name = @OverrideDB;

-- create powershell move statement
SELECT	'Move-Item \\' + @ServerName + '\' + REPLACE(physical_name,':','$')
		+ ' \\' + @ServerName + '\' + REPLACE(@NewFilePath,':','$') AS PowerShellMoveScript
FROM	sys.master_files
WHERE	@OverrideDB = DB_NAME(database_id)
AND		@TargetFile = name;

-- create alter statement
SELECT	'ALTER DATABASE ' + DB_NAME(database_id) + '
		MODIFY FILE ( NAME = ''' + name + '''
		,FILENAME = ''' + @NewFilePath + ''');'
FROM    sys.master_files
WHERE  @OverrideDB = DB_NAME(database_id)
AND		@TargetFile = name;

-- create online statement
SELECT  'ALTER DATABASE ' + name + ' SET ONLINE;' AS OnlineDatabase
FROM    sys.databases
WHERE   name = @OverrideDB;
