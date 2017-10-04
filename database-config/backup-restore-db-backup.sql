-- Set database context to DB to be restored
USE [DB Name];
GO

DECLARE @BakFile NVARCHAR(MAX) = N'<bak file path and filename>';

-- Get file list from backup
RESTORE FILELISTONLY FROM DISK = @BakFile;
GO

-- Return database file locations
EXEC sys.sp_helpfile;
GO

-- Set database context to master
USE master;
GO

-- Take tail log back up
BACKUP LOG [DB Name]
TO  DISK = N'<bak log file path and filename>'
WITH NOFORMAT
    ,NOINIT
    ,NOSKIP
    ,NOREWIND
    ,NOUNLOAD
    ,STATS = 10;

-- Restore the database
RESTORE DATABASE [DB Name]
FROM DISK = N'<bak file path and filename>'
WITH RECOVERY -- roll back uncommitted transactions
    -- NORECOVERY -- use for multi-step restore sequence until desired recovery point is reached, does not roll back uncommitted transactions
    ,REPLACE
    ,MOVE '<Data File>' TO '<data file path and filename>'
    ,MOVE '<Log File>' TO '<log file path and filename>'
    ,STATS = 10;
GO

