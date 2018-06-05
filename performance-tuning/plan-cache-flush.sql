-- Eight different ways to clear the plan cache
-- Glenn Berry
-- SQLskills.com
-- https://www.sqlskills.com/blogs/glenn/eight-different-ways-to-clear-the-sql-server-plan-cache/    


-- Example 1 ***********************
-- Remove all elements from the plan cache for the entire instance 
DBCC FREEPROCCACHE;


-- Example 2 ***********************
-- Flush the plan cache for the entire instance and suppress the regular completion message
-- "DBCC execution completed. If DBCC printed error messages, contact your system administrator." 
DBCC FREEPROCCACHE WITH NO_INFOMSGS;


-- Example 3 ***********************
-- Flush the ad hoc and prepared plan cache for the entire instance
DBCC FREESYSTEMCACHE('SQL Plans');


-- Example 4 ***********************
-- Flush the ad hoc and prepared plan cache for one resource pool

-- Get Resource Pool information
SELECT  name                     AS [Resource Pool Name]
       ,cache_memory_kb / 1024.0 AS [cache_memory (MB)]
       ,used_memory_kb / 1024.0  AS [used_memory (MB)]
FROM    sys.dm_resource_governor_resource_pools;

-- Flush the ad hoc and prepared plan cache for one resource pool
DBCC FREESYSTEMCACHE('SQL Plans', 'LimitedIOPool');


-- Example 5 **********************
-- Flush the entire plan cache for one resource pool

-- Get Resource Pool information
SELECT  name                     AS [Resource Pool Name]
       ,cache_memory_kb / 1024.0 AS [cache_memory (MB)]
       ,used_memory_kb / 1024.0  AS [used_memory (MB)]
FROM    sys.dm_resource_governor_resource_pools;


-- Flush the plan cache for one resource pool
DBCC FREEPROCCACHE('LimitedIOPool');


-- Example 6 **********************
-- Remove all elements from the plan cache for one database (does not work in SQL Azure) 

-- Get DBID from one database name first
DECLARE @intDBID INT;
SET @intDBID = (SELECT dbid FROM master.sys.sysdatabases WHERE name = N'rp_util');

-- Flush the plan cache for one database only
DBCC FLUSHPROCINDB(@intDBID);


-- Example 7 **********************
-- Clear plan cache for the current database

USE rp_util;
GO
-- Clear plan cache for the current database
-- New in SQL Server 2016 and SQL Azure
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;



-- Example 8 **********************
-- Remove one query plan from the cache

USE rp_util;
GO

-- Run a stored procedure or query
EXEC dbo.uspGetEmployeeManagers 9;

-- Find the plan handle for that query 
-- OPTION (RECOMPILE) keeps this query from going into the plan cache
SELECT  cp.plan_handle
       ,cp.objtype
       ,cp.usecounts
       ,DB_NAME(st.dbid) AS DatabaseName
FROM    sys.dm_exec_cached_plans                         AS cp
        CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE   OBJECT_NAME(st.objectid) LIKE N'%uspGetEmployeeManagers%'
OPTION (RECOMPILE);

-- Remove the specific query plan from the cache using the plan handle from the above query 
DBCC FREEPROCCACHE(0x050011007A2CC30E204991F30200000001000000000000000000000000000000000000000000000000000000);
