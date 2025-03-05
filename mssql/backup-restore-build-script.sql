DECLARE @database VARCHAR(128) = 'DBName'
		,@DRDataCenter VARCHAR(100) = 'DRDataCenter'
		,@DRRepository VARCHAR(100) = 'DRRepoName';

;WITH Baks AS (
	SELECT bs.database_name
			,bs.type
			,bs.media_set_id
			,bs.backup_start_date
			,bmf.physical_device_name
			,SUBSTRING(bmf.physical_device_name,3,CHARINDEX('\',bmf.physical_device_name,3)-3) AS PrimaryDataCenter
			,SUBSTRING(bmf.physical_device_name,CHARINDEX('\',bmf.physical_device_name,3)+1,CHARINDEX('\',bmf.physical_device_name,3)) AS PrimaryRepository
			,ISNULL(@DRDataCenter,SUBSTRING(bmf.physical_device_name,3,CHARINDEX('\',bmf.physical_device_name,3)-3)) AS DRDataCenter
			,ISNULL(@DRRepository,SUBSTRING(bmf.physical_device_name,CHARINDEX('\',bmf.physical_device_name,3)+1,CHARINDEX('\',bmf.physical_device_name,3)-2)) AS DRRepository
	FROM msdb.dbo.backupset bs
		JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
	WHERE bs.type IN ('D', 'I', 'L') -- 'Full backup', 'Diff backup', 'Log'
	AND	(bs.database_name = @database OR @database IS NULL)
)
,LatestFull AS (
	SELECT database_name, MAX(backup_start_date) as backup_start_date
	FROM	Baks
	WHERE	type = 'D'
	GROUP BY database_name
)
,LatestDiff AS (
	SELECT database_name, MAX(backup_start_date) as backup_start_date
	FROM	Baks
	WHERE	type = 'I'
	GROUP BY database_name
)
,LatestLogs AS (
	SELECT b.database_name
			,b.media_set_id
			,DENSE_RANK() OVER (PARTITION BY b.database_name ORDER BY b.backup_start_date) AS BakOrder
	FROM	Baks b
			JOIN LatestDiff f
				ON b.database_name = f.database_name
				AND b.backup_start_date > f.backup_start_date
	WHERE	b.type = 'L'
)
SELECT b.database_name
		,'RESTORE DATABASE ' + b.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + bmf.physical_device_name + ''''
			FROM	Baks bmf
			WHERE	b.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY, STATS = 10;' AS PrimaryDataCenterRestore
		,'RESTORE DATABASE ' + b.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + REPLACE(REPLACE(bmf.physical_device_name,bmf.PrimaryDataCenter,DRDataCenter),bmf.PrimaryRepository,DRRepository) + ''''
			FROM	Baks bmf
			WHERE	b.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY, STATS = 10;' AS DRDataCenterRestore
		,0 AS BakOrder
FROM Baks b
	JOIN LatestFull f
		ON b.database_name = f.database_name
		and b.backup_start_date = f.backup_start_date
UNION ALL	
SELECT b.database_name
		,'RESTORE DATABASE ' + b.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + bmf.physical_device_name + ''''
			FROM	Baks bmf
			WHERE	b.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY, STATS = 10;' AS PrimaryDataCenterRestore
		,'RESTORE DATABASE ' + b.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + REPLACE(REPLACE(bmf.physical_device_name,bmf.PrimaryDataCenter,DRDataCenter),bmf.PrimaryRepository,DRRepository) + ''''
			FROM	Baks bmf
			WHERE	b.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY, STATS = 10;' AS DRDataCenterRestore
		,0 AS BakOrder
FROM Baks b
	JOIN LatestDiff f
		ON b.database_name = f.database_name
		and b.backup_start_date = f.backup_start_date
UNION ALL		
SELECT l.database_name
		,'RESTORE LOG ' + l.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + bmf.physical_device_name + ''''
			FROM	Baks bmf
			WHERE	l.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY;'
		,'RESTORE LOG ' + l.database_name + ' FROM ' +
		STUFF((
			SELECT	',' + 'DISK = N''' + REPLACE(REPLACE(bmf.physical_device_name,bmf.PrimaryDataCenter,DRDataCenter),bmf.PrimaryRepository,DRRepository) + ''''
			FROM	Baks bmf
			WHERE	l.media_set_id = bmf.media_set_id
			FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'')
		+ ' WITH  NORECOVERY;'
		,l.BakOrder
FROM LatestLogs l
UNION
SELECT database_name
		,'--RESTORE DATABASE ' + database_name + ' WITH RECOVERY;'
		,CONVERT(VARCHAR(50),backup_start_date,100)
		,10000 AS BakOrder
FROM	LatestFull
ORDER BY 1,4


