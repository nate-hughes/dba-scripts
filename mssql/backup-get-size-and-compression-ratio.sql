WITH MaxDate AS (
	SELECT database_name
		, MAX(backup_finish_date) AS backup_finish_date
	FROM msdb..backupset
	GROUP BY database_name
)

SELECT b.database_name
	, b.backup_size/1024/1024/1024 AS backup_size_GB
	, b.compressed_backup_size/1024/1024/1024 AS compressed_backup_size_GB
	, b.backup_size/b.compressed_backup_size AS CompressedRatio
FROM msdb..backupset b
	JOIN MaxDate d ON b.database_name = d.database_name and b.backup_finish_date = d.backup_finish_date
ORDER BY 1;

--SELECT AVG(backup_size/compressed_backup_size) AS AvgCompressedRatio
--FROM msdb..backupset;
