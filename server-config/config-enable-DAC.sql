Use master
GO
/* 0 = Allow Local Connection, 1 = Allow Remote Connections*/ 
sp_configure 'remote admin connections', 1 
GO
RECONFIGURE
GO

/*
-- Using DAC with SQLCMD
SQLCMD –S [SQL Server Name] –U [User Name] –P [Password] –A 

-- SSMS
-- specify “ADMIN:” before the SQL Server Instance name
*/

/* Common DAC requests */
-- Active Locks
SELECT * FROM sys.dm_tran_locks
GO
-- Cache Status
SELECT * FROM sys.dm_os_memory_cache_counters 
GO
-- Active Sessions
SELECT * FROM sys.dm_exec_sessions 
GO
-- Requests Status
SELECT * FROM sys.dm_exec_requests
GO
