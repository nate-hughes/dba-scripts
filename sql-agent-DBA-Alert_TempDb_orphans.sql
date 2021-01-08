USE master;
GO
DROP PROC IF EXISTS dbo.TempDbAlert;
GO
CREATE PROC dbo.TempDbAlert
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	COALESCE(T1.session_id, T2.session_id) [session_id]
		,S.status
		,S.login_name
		,S.host_name
		,S.program_name
		,S.last_request_start_time
		,S.last_request_end_time
		,S.open_transaction_count
		,COALESCE(T1.[Net Allocation], 0) + T2.[Net Allocation] [Net Allocation MB]
		--,COALESCE(T1.[Query Text], T2.[Query Text]) [Query Text]
		,T.text [Query Text]
FROM    (
			SELECT	TS.session_id
					,CAST(MAX(TS.user_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation User Objects]
					,CAST((MAX(TS.user_objects_alloc_page_count) - MAX(TS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation User Objects]
					,CAST(SUM(TS.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation Internal Objects]
					,CAST((SUM(TS.internal_objects_alloc_page_count) - SUM(TS.internal_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation Internal Objects]
					,CAST((MAX(TS.user_objects_alloc_page_count) + SUM(internal_objects_alloc_page_count)) / 128 AS DECIMAL(15,2)) [Total Allocation]
					,CAST((MAX(TS.user_objects_alloc_page_count)
						+ SUM(TS.internal_objects_alloc_page_count)
						- SUM(TS.internal_objects_dealloc_page_count)
						- MAX(TS.user_objects_dealloc_page_count) ) / 128 AS DECIMAL(15,2)) [Net Allocation]
					--,T.text [Query Text]
					,ER.sql_handle
			FROM	sys.dm_db_task_space_usage TS
					INNER JOIN sys.dm_exec_requests ER
						ON ER.request_id = TS.request_id
						AND ER.session_id = TS.session_id
					--OUTER APPLY sys.dm_exec_sql_text(ER.sql_handle) T
			GROUP BY TS.session_id
					,ER.sql_handle
        ) T1
        RIGHT JOIN (
			SELECT	SS.session_id
					,CAST(MAX(SS.user_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation User Objects]
					,CAST((MAX(SS.user_objects_alloc_page_count) - MAX(SS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation User Objects]
					,CAST(SUM(SS.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) [Total Allocation Internal Objects]
					,CAST((SUM(SS.internal_objects_alloc_page_count) - SUM(SS.internal_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation Internal Objects]
					,CAST((MAX(SS.user_objects_alloc_page_count) + SUM(internal_objects_alloc_page_count)) / 128 AS DECIMAL(15,2)) [Total Allocation]
					,CAST((MAX(SS.user_objects_alloc_page_count)
						+ SUM(SS.internal_objects_alloc_page_count)
						- SUM(SS.internal_objects_dealloc_page_count)
						- MAX(SS.user_objects_dealloc_page_count)) / 128 AS DECIMAL(15,2)) [Net Allocation]
					--,T.text [Query Text]
					,CN.most_recent_sql_handle
			FROM	sys.dm_db_session_space_usage SS
					LEFT JOIN sys.dm_exec_connections CN ON CN.session_id = SS.session_id
					--OUTER APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) T
			GROUP BY SS.session_id
					,CN.most_recent_sql_handle
	) T2 ON T1.session_id = T2.session_id
	OUTER APPLY sys.dm_exec_sql_text(COALESCE(T1.sql_handle,T2.most_recent_sql_handle)) T
	JOIN sys.dm_exec_sessions S ON s.session_id = COALESCE(T1.session_id, T2.session_id)
WHERE	COALESCE(T1.[Net Allocation],0) + COALESCE(T2.[Net Allocation],0) > 0
ORDER BY [Net Allocation MB] DESC;
GO


USE tempdb;
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE	@Recipients VARCHAR(1000) = 'nate.hughes@bestegg.com'
		,@Threshold_Hours INT = 48
		,@Threshold_Size_MB INT = 1000
		,@pgsz NUMERIC(19,10)
		,@Body VARCHAR(MAX)
		,@Subject VARCHAR(100)
		,@VolumeFreeSpacePct NUMERIC(9,5);

SELECT	@pgsz = [low] * 0.0009765625 /*KB*/ * 0.0009765625 /*MB*/
FROM	[master].dbo.spt_values
WHERE	number = 1
AND		type = 'E';

SELECT	@VolumeFreeSpacePct = x.available_bytes * 1.0 / x.total_bytes
FROM	(
			SELECT	
					volume_mount_point
					,total_bytes
					,available_bytes
					--,available_bytes * 1.0 / total_bytes
			FROM	sys.database_files AS f  
					CROSS APPLY sys.dm_os_volume_stats(2, f.file_id)
			GROUP BY volume_mount_point
					,total_bytes
					,available_bytes
		) x;

DECLARE @TempDbInventory TABLE (
	row_id INT IDENTITY(1,1)
	,session_id INT
	,Status VARCHAR(100)
	,login_name VARCHAR(100)
	,host_name VARCHAR(100)
	,program_name VARCHAR(100)
	,last_request_start_time DATETIME
	,last_request_end_time DATETIME
	,HoursSinceLastRequest AS DATEDIFF(HOUR,last_request_end_time,GETDATE())
	,open_transaction_count INT
	,tempdb_current_size_mb BIGINT
	,text VARCHAR(MAX)
);

DECLARE @TempDbFiles TABLE (
	FileName VARCHAR(128)
	,FileGroupName VARCHAR(128)
	,Size BIGINT
	,SpaceUsed BIGINT
	,type TINYINT
	,file_id INT
	,physical_name VARCHAR(260)
);

-- if Free Space < 15% then pull tempdb usage
IF @VolumeFreeSpacePct <= .15
BEGIN
	INSERT @TempDbInventory (
		session_id, login_name, host_name, program_name, Status, last_request_start_time, last_request_end_time, open_transaction_count, tempdb_current_size_mb, text
	)
	EXEC master.dbo.TempDbAlert;

	INSERT @TempDbFiles (
		FileName, FileGroupName, Size, SpaceUsed, type, file_id, physical_name
	)
	SELECT	f.name
			,CASE WHEN f.type = 1 THEN 'LOG'
				ELSE s.name
			END
			,CONVERT(BIGINT, f.size * @pgsz)
			,CONVERT(BIGINT, FILEPROPERTY(f.name, 'SpaceUsed') * @pgsz)
			,f.type
			,f.file_id
			,f.physical_name
	FROM	sys.database_files f
			LEFT OUTER JOIN sys.data_spaces s
				ON f.data_space_id = s.data_space_id;
END;

IF EXISTS (SELECT 1 FROM @TempDbInventory)
AND EXISTS (SELECT 1 FROM @TempDbFiles WHERE TRY_CONVERT(NUMERIC(4,1), SpaceUsed * 1.0 / Size * 100) >= 75.0)
BEGIN
	SET @Subject = @@ServerName + ' TempDb ALERT';

	SET @Body = '<html><head><style>' +
				'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
				'</style></head>' +
				'<body><table cellpadding=0 cellspacing=0 border=0>' +
				'<tr><td align=center bgcolor=#E6E6FA><b>ROW ID</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>SPID</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>Status</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>Login</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>HostName</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>ProgramName</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>ConnectionEstablished</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>LastRequest</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>HoursSinceLastRequest</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>OpenTransactions</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>CurrentSize_MB</b></td>'+
				'</tr>';
				
	SELECT @Body += (
		SELECT	td= row_number() over (order by tempdb_current_size_mb desc ),'',		
				td= session_id,'',
				td= Status,'',		
				td= login_name,'',
				td= host_name,'',
				td= program_name,'',
				td= TRY_CONVERT(VARCHAR(50),last_request_start_time,100),'',
				td= TRY_CONVERT(VARCHAR(50),last_request_end_time,100),'',
				td= HoursSinceLastRequest,'',	
				td= open_transaction_count,'',	
				td= tempdb_current_size_mb,''
		FROM  @TempDbInventory
		WHERE row_id <= 10
		For XML RAW('tr'), ELEMENTS
	);

	SET @Body += '</table><hr><hr>';
	
	SET @Body += '<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr><td align=center bgcolor=#E6E6FA><b>ROW ID</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>FileName</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>FileGroupName</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>FileSize_MB</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>FileSizeUsed_MB</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>FileSizeUsedPct</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>FileSizeUnused_MB</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>FileSizeUnusedPct</b></td>'+
				'<td align=center bgcolor=#E6E6FA><b>PhysicalName</b></td></tr>';
				
	SELECT @Body += (
		SELECT	td= row_number() over (order by type, file_id ),'',		
				td= FileName,'',
				td= FileGroupName,'',		
				td= Size,'',
				td= SpaceUsed,'',
				td= TRY_CONVERT(VARCHAR(50),CONVERT(NUMERIC(4,1), SpaceUsed * 1.0 / Size * 100)),'',
				td= TRY_CONVERT(VARCHAR(50),(Size - SpaceUsed),100),'',
				td= TRY_CONVERT(VARCHAR(50),CONVERT(NUMERIC(4,1), (Size - SpaceUsed) * 1.0 / Size * 100)),'',
				td= physical_name,''
		FROM  @TempDbFiles
		For XML RAW('tr'), ELEMENTS
	);
		
	SET @Body += '</table></body></html>';

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = @Recipients
		,@subject = @Subject
		,@profile_name = 'DBMail'
		,@body = @Body
		,@body_format = 'HTML';
END;
GO