
SELECT	@@SERVERNAME AS servername 
		,s.name AS linkedservername
		,s.product AS productname
		,s.provider AS OLEDBprovidername
		,s.data_source AS OLEDBdatasource
		,s.is_remote_login_enabled
		,s.is_rpc_out_enabled
		,s.is_data_access_enabled
		,s.is_collation_compatible
		,s.uses_remote_collation
		,s.collation_name
		,s.lazy_schema_validation
		,s.is_system
		,s.is_remote_proc_transaction_promotion_enabled
		,s.modify_date as linkedserver_modify_date
		,ll.uses_self_credential
		,c.name AS local_login
		,ll.remote_name
		,ll.modify_date as login_modify_date
FROM	sys.Servers s
		LEFT OUTER JOIN sys.linked_logins ll ON ll.server_id = s.server_id
		LEFT OUTER JOIN sys.server_principals c ON c.principal_id = ll.local_principal_id
WHERE	s.server_id > 0; -- 0 = local server

