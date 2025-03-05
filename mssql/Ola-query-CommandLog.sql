
DECLARE @ClusterName VARCHAR(128);

SELECT	@ClusterName = cluster_name
FROM	master.sys.dm_hadr_cluster
WHERE	LEFT(cluster_name, 1) LIKE '[a-z]';

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DBMaint')
	IF EXISTS (SELECT 1 FROM DBMaint.sys.tables WHERE name = 'CommandLog')
		SELECT	@ClusterName AS clustername
				,@@SERVERNAME AS ServerName
				,DEFAULT_DOMAIN() AS Domain
				,DatabaseName
				,SchemaName
				,ObjectName
				,ObjectType
				,IndexName
				,IndexType
				,PartitionNumber
				,ExtendedInfo.value('(/ExtendedInfo/PageCount)[1]', 'int') AS PageCount
				,ExtendedInfo.value('(/ExtendedInfo/Fragmentation)[1]', 'numeric(9,4)') AS Fragmentation
				,TRY_CONVERT(VARCHAR(2000),Command) AS Command
				,CommandType
				,StartTime
				,EndTime
				,ErrorNumber
				,TRY_CONVERT(VARCHAR(2000),ErrorMessage) AS ErrorMessage
		FROM	dbo.CommandLog
		WHERE	CommandType IN ('ALTER_INDEX', 'DBCC_CHECKDB', 'BACKUP_DATABASE')
		AND		EndTime IS NOT NULL;
