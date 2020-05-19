
SELECT DISTINCT @@SERVERNAME as servername
	,DEFAULT_DOMAIN() as domain
	,s.file_system_type
	,s.volume_mount_point
	,s.logical_volume_name
	,s.total_bytes
	,s.available_bytes  
	,s.supports_compression
	,s.supports_alternate_streams
	,s.supports_sparse_files
	,s.is_read_only
	,s.is_compressed
FROM sys.master_files AS f  
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) s;

