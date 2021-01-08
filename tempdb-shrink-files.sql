USE tempdb;
GO

SELECT	volume_mount_point
		, x.available_bytes * 1.0 / x.total_bytes AS VolumeFreeSpacePct
FROM	(
			SELECT	
					volume_mount_point
					,total_bytes
					,available_bytes
					--,available_bytes * 1.0 / total_bytes
			FROM	sys.database_files AS f  
					CROSS APPLY sys.dm_os_volume_stats(2, f.file_id)
			GROUP BY volume_mount_point
					,total_bytes
					,available_bytes
		) x;

		
SELECT	name
		,physical_name AS CurrentLocation
		,size / 128 AS size_MB
		,growth / 128 AS growth_MB
		,'CHECKPOINT; DBCC FREEPROCCACHE; DBCC SHRINKFILE (N''' + name + ''' , ' + CONVERT(VARCHAR(50),size / 128) + ');' AS ShrinkFile
		,'ALTER DATABASE [tempdb] MODIFY FILE (NAME = N''' + name + ''', SIZE = ' + CONVERT(VARCHAR(50),size / 128) + ');' AS AlterSize
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');
