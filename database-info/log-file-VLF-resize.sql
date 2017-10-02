USE [?]
GO

-- Step 1
-- run and then paste shrink and resize stmts into Step 2
select name
	, CurrentSize_MB = CONVERT(BIGINT,size)*8/1024
	, ShrinkLog = 'DBCC SHRINKFILE (' + name + ', 0)'
	, ResizeLog = 'ALTER DATABASE ' + DB_NAME() + ' MODIFY FILE (NAME = ''' + name + ''', SIZE = '
					+ CASE WHEN CONVERT(BIGINT,size)*8/1024. < 1024 THEN CONVERT(VARCHAR(10),CONVERT(BIGINT,size)*8/1024)+ 'MB)'
							WHEN CONVERT(BIGINT,size)*8/1024. >= 1024 THEN CONVERT(VARCHAR(10),CONVERT(BIGINT,size)*8/1024/1024)+ 'GB)'
						END
	, Used_MB = CONVERT(BIGINT, FILEPROPERTY(name, 'SpaceUsed'))*8/1024
from sys.master_files
where database_id = DB_ID()
AND type_desc = 'LOG';
GO


-- Step 2
DBCC LogInfo
GO
CHECKPOINT
GO
-- COPY 'ShrinkLog' HERE --

GO
-- COPY 'ResizeLog' HERE --
-- if > 8 GB then break into 8 GB expansions

GO
DBCC LogInfo
GO
