
:Connect TargetReplica
SELECT	e.name, e.principal_id, p.name as principal, e.protocol_desc, e.type_desc, e.state_desc
		,dm.role_desc, dm.connection_auth_desc, dm.encryption_algorithm_desc
		,t.port
FROM	sys.endpoints e
		LEFT JOIN sys.database_mirroring_endpoints dm ON e.endpoint_id = dm.endpoint_id
		LEFT JOIN sys.tcp_endpoints t ON e.endpoint_id = t.endpoint_id
		JOIN sys.server_principals p ON e.principal_id = p.principal_id;


:Connect TargetReplica
CREATE ENDPOINT [Hadr_endpoint]
   STATE=STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
   FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE , ENCRYPTION = REQUIRED ALGORITHM AES)
GO
ALTER AUTHORIZATION ON ENDPOINT::Hadr_Endpoint TO SA
GO
GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [domain\SvcAcct];  
GO
--ALTER ENDPOINT Hadr_Endpoint STATE = STARTED
--GO
