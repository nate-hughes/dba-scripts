SELECT TRY_CONVERT(INT,(SUM(unallocated_extent_page_count)*1.0/128)) AS TempDB_FreeSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT TRY_CONVERT(INT,(SUM(version_store_reserved_page_count)*1.0/128)) AS TempDB_VersionStoreSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT TRY_CONVERT(INT,(SUM(internal_object_reserved_page_count)*1.0/128)) AS TempDB_InternalObjSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT TRY_CONVERT(INT,(SUM(user_object_reserved_page_count)*1.0/128)) AS TempDB_UserObjSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;

SELECT session_id,
    SUM(internal_objects_alloc_page_count) / 128 AS MBAllocatedInTempDBforInternalTask,
    SUM(internal_objects_dealloc_page_count) / 128 AS MBDellocatedInTempDBforInternalTask,
    SUM(user_objects_alloc_page_count) / 128 AS MBAllocatedInTempDBforUserTask,
    SUM(user_objects_dealloc_page_count) / 128 AS MBDellocatedInTempDBforUserTask
FROM sys.dm_db_task_space_usage
GROUP BY session_id
ORDER BY MBAllocatedInTempDBforInternalTask DESC, MBAllocatedInTempDBforUserTask DESC

SELECT 
  DB_NAME(database_id) as 'Database Name',
  reserved_page_count,
  reserved_page_count / 128 as reserved_mb
FROM sys.dm_tran_version_store_space_usage
ORDER BY 3 desc; 