

SELECT	[SrvId] = s.server_id
		, [SrvEnabled] = s.is_data_access_enabled
		, [SrvName] = s.name
		, [SrvProduct] = s.product
		, [SrvProvider] = s.provider
		, [SrvDataSource] = s.data_source
		, [LocalLogin] = ISNULL(c.name,'')
		, [RemoteLogin]	= ISNULL(ll.remote_name,'')
		, [OutgoingRPCEnabled] = s.is_rpc_out_enabled
		, [DTCEnabled] = s.is_remote_proc_transaction_promotion_enabled
		, [ModifiedDate] = s.modify_date
FROM	sys.Servers s
		LEFT OUTER JOIN sys.linked_logins ll ON ll.server_id = s.server_id
		LEFT OUTER JOIN sys.server_principals c ON c.principal_id = ll.local_principal_id
WHERE	s.server_id > 0
ORDER BY s.name;

--exec sp_linkedservers