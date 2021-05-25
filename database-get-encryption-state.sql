SELECT	d.name AS [database]
		,d.is_encrypted
		,dek.encryption_state
		,dek.percent_complete
		,dek.key_algorithm
		,dek.key_length
FROM	master.sys.databases d
		LEFT JOIN master.sys.dm_database_encryption_keys dek ON d.database_id = dek.database_id
ORDER BY d.name;