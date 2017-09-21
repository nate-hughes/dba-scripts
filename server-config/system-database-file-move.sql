USE [master]
GO

-- move master
/*
-dF:\SQL_DATA\master.mdf
-lF:\SQL_LOG\mastlog.ldf
*/

/*
SELECT name, physical_name AS CurrentLocation
FROM sys.master_files
WHERE database_id = DB_ID(N'model');
*/

-- move msdb
ALTER DATABASE msdb 
MODIFY FILE (NAME = MSDBData, FILENAME = 'F:\SQL_DATA\MSDBData.mdf');
GO
ALTER DATABASE msdb 
MODIFY FILE (NAME = MSDBLog, FILENAME = 'F:\SQL_LOG\MSDBLog.ldf');
GO

-- move model
ALTER DATABASE model 
MODIFY FILE (NAME = modeldev, FILENAME = 'F:\SQL_DATA\model.mdf');
GO
ALTER DATABASE model 
MODIFY FILE (NAME = modellog, FILENAME = 'F:\SQL_LOG\modellog.ldf');
GO

-- move TempDB
ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'T:\TempDb\tempdb.mdf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'T:\TempDb\templog.ldf');
GO

-- move ReportServer
ALTER DATABASE ReportServer 
MODIFY FILE (NAME = ReportServer, FILENAME = 'F:\SQL_DATA\ReportServer.mdf');
GO
ALTER DATABASE ReportServer 
MODIFY FILE (NAME = ReportServer_log, FILENAME = 'F:\SQL_LOG\ReportServer_log.ldf');
GO

-- move ReportServerTempDB
ALTER DATABASE ReportServerTempDB 
MODIFY FILE (NAME = ReportServerTempDB, FILENAME = 'F:\SQL_DATA\ReportServerTempDB.mdf');
GO
ALTER DATABASE ReportServerTempDB 
MODIFY FILE (NAME = ReportServerTempDB_log, FILENAME = 'F:\SQL_LOG\ReportServerTempDB_log.ldf');
GO