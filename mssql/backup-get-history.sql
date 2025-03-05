
DECLARE @ClusterName VARCHAR(128);

SELECT	@ClusterName = cluster_name
FROM	master.sys.dm_hadr_cluster
WHERE	LEFT(cluster_name, 1) LIKE '[a-z]';

WITH BakOrder AS (
	SELECT	database_name
			,type
			,backup_start_date
			,DENSE_RANK() OVER (PARTITION BY database_name, type ORDER BY backup_start_date DESC) AS BakOrder
	FROM	msdb.dbo.backupset
	WHERE	backup_finish_date IS NOT NULL
)
SELECT	@ClusterName AS clustername
		,@@SERVERNAME AS servername
		,DEFAULT_DOMAIN() as domain
		,d.name as dbname
		,bs.backup_set_uuid
		,bs.position
		,bs.expiration_date
		,bs.name
		,bs.description
		,bs.user_name
		,bs.first_lsn
		,bs.last_lsn
		,bs.backup_start_date
		,bs.backup_finish_date
		,bs.type
		,bs.backup_size
		,bs.compatibility_level
		,bs.is_password_protected
		,bs.recovery_model
		,bs.has_bulk_logged_data
		,bs.is_snapshot
		,bs.is_readonly
		,bs.is_single_user
		,bs.has_backup_checksums
		,bs.is_damaged
		,bs.is_copy_only
		,bs.compressed_backup_size
		,bmf.family_sequence_number
		,bmf.logical_device_name
		,bmf.physical_device_name
		,bmf.device_type
FROM	master.sys.databases d
		LEFT OUTER JOIN BakOrder o ON o.database_name = d.name and o.BakOrder = 1
		LEFT OUTER JOIN msdb.dbo.backupset bs ON bs.database_name = o.database_name AND bs.type = o.type AND bs.backup_start_date = o.backup_start_date
		LEFT OUTER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE	d.name <> 'tempdb';
