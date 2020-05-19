USE [master];
GO
SELECT name, is_query_store_on, is_read_committed_snapshot_on FROM sys.databases;
GO

-- Change The Isolation Level Of An Availability Group Database
-- http://www.sqlnuggets.com/blog/change-the-isolation-level-of-an-availability-group-database/

ALTER DATABASE [DBName] SET QUERY_STORE = ON
GO
ALTER DATABASE [DBName] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, INTERVAL_LENGTH_MINUTES = 5, MAX_STORAGE_SIZE_MB = 2000)
GO
ALTER AVAILABILITY GROUP [AGName] REMOVE DATABASE [DBName];
GO
ALTER DATABASE [DBName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DBName] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [DBName] SET MULTI_USER
GO
ALTER AVAILABILITY GROUP [AGName] ADD DATABASE [DBName];
GO

-- run on each of the secondaries
:CONNECT [SecondaryReplica]
ALTER DATABASE [DBName] SET HADR AVAILABILITY GROUP = aagLaunchpad;
GO

