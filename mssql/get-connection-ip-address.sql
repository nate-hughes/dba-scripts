SELECT dec.local_net_address, dec.local_tcp_port
FROM sys.dm_exec_connections AS dec
WHERE dec.session_id = @@SPID;