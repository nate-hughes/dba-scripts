
SELECT	bak.database_name
		, COALESCE(CASE WHEN SUM(bak.BakOrder) > 1 THEN 'FULL+DIFF'END
			,MAX(CASE WHEN bak.backup_type <> 'No backups' THEN 'FULL' END)) AS backup_type
		, MAX(CASE WHEN bak.backup_type <> 'No backups' AND bak.CompressionRatio < 100.0 THEN 1
				WHEN bak.backup_type <> 'No backups' THEN 0
			END) AS UsedCompression
		, MAX(bak.has_backup_checksums) AS UsedChecksum
		, MAX(CASE WHEN bak.backup_type = 'Full backup' OR bak.backup_type = 'Partial' THEN bak.backup_start_date END) AS MostRecentFull_Date
		, MAX(CASE WHEN bak.backup_type = 'Full backup' OR bak.backup_type = 'Partial' THEN DATEDIFF(SECOND,bak.backup_start_date,bak.backup_finish_date) END) AS MostRecentFull_Sec
		, SUM(CASE WHEN bak.backup_type = 'Full backup' OR bak.backup_type = 'Partial' THEN bak.MostRecentSize_MB END) AS MostRecentFull_MB
		, MAX(CASE WHEN bak.backup_type <> 'Full backup' AND bak.backup_type <> 'Partial' THEN bak.backup_type END) AS MostRecentOther
		, MAX(CASE WHEN bak.backup_type <> 'Full backup' AND bak.backup_type <> 'Partial' THEN bak.backup_start_date END) AS MostRecentOther_Date
		, MAX(CASE WHEN bak.backup_type <> 'Full backup' AND bak.backup_type <> 'Partial' THEN DATEDIFF(SECOND,bak.backup_start_date,bak.backup_finish_date) END) AS MostRecentOther_Sec
		, SUM(CASE WHEN bak.backup_type <> 'Full backup' AND bak.backup_type <> 'Partial' THEN bak.MostRecentSize_MB END) AS MostRecentOther_MB
FROM	(
			SELECT	d.name AS database_name
					, CASE bs.type
							WHEN 'D' THEN 'Full backup'
							WHEN 'I' THEN 'Differential'
							WHEN 'L' THEN 'Log'
							WHEN 'F' THEN 'File/Filegroup'
							WHEN 'G' THEN 'Differential file'
							WHEN 'P' THEN 'Partial'
							WHEN 'Q' THEN 'Differential partial'
							WHEN NULL THEN 'No backups'
							ELSE 'Unknown (' + bs.[type] + ')'
						END AS backup_type
					, (CONVERT(INT, bs.compressed_backup_size / 1024 /*KB*/ / 1024 /*MB*/)) AS [MostRecentSize_MB]
					, bmf.physical_device_name
					, CASE WHEN bmf.device_type IN (2, 102) THEN 'DISK'
							WHEN bmf.device_type IN (5, 105) THEN 'TAPE'
						END AS device_type
					, DENSE_RANK() OVER (PARTITION BY bs.database_name, bs.type ORDER BY bs.backup_start_date DESC) AS BakOrder
					,bs.backup_start_date
					,bs.backup_finish_date
					,CONVERT(NUMERIC(4,1), (1 - (bs.compressed_backup_size * 1.0 / NULLIF(bs.backup_size, 0))) * 100) AS CompressionRatio
					,CAST(bs.has_backup_checksums AS TINYINT) AS has_backup_checksums
			FROM	master.sys.databases d
					LEFT OUTER JOIN msdb.dbo.backupset bs ON bs.database_name = d.name
					LEFT OUTER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
		) bak
WHERE	bak.BakOrder = 1
GROUP BY bak.database_name
ORDER BY bak.database_name;
