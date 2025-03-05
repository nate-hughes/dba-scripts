SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE	@Recipients VARCHAR(1000) = 'dba@domain.com'
		,@Threshold_Hours INT = 48
		,@Threshold_Size_MB INT = 1000
		,@pgsz NUMERIC(19,10)
		,@Body VARCHAR(MAX)
		,@Subject VARCHAR(100)
		,@VolumeFreeSpacePct NUMERIC(9,5)
		,@TempDbFreeSpacePct NUMERIC(9,5);

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

DECLARE @TempDbUsage TABLE (
	TotalSpaceInMB INT
	,FreeSpaceInMB INT
	,VersionStoreSpaceInMB INT
	,InternalObjSpaceInMB INT
	,UserObjSpaceInMB INT
);

INSERT @TempDbUsage (
	TotalSpaceInMB, FreeSpaceInMB, VersionStoreSpaceInMB, InternalObjSpaceInMB, UserObjSpaceInMB
)
SELECT	TRY_CONVERT(INT,(SUM(total_page_count)*1.0/128)) AS TotalSpaceInMB
		,TRY_CONVERT(INT,(SUM(unallocated_extent_page_count)*1.0/128)) AS FreeSpaceInMB
		,TRY_CONVERT(INT,(SUM(version_store_reserved_page_count)*1.0/128)) AS VersionStoreSpaceInMB
		,TRY_CONVERT(INT,(SUM(internal_object_reserved_page_count)*1.0/128)) AS InternalObjSpaceInMB
		,TRY_CONVERT(INT,(SUM(user_object_reserved_page_count)*1.0/128)) AS UserObjSpaceInMB
FROM tempdb.sys.dm_db_file_space_usage;

SELECT @TempDbFreeSpacePct = FreeSpaceInMB * 1.0 / TotalSpaceInMB
FROM	@TempDbUsage;

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

---- if Volume Free Space < 15% then generate alert
--IF @VolumeFreeSpacePct <= .15
-- if TempDb Free Space < 30% then generate alert
IF @TempDbFreeSpacePct <= .3
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
--AND EXISTS (SELECT 1 FROM @TempDbFiles WHERE TRY_CONVERT(NUMERIC(4,1), SpaceUsed * 1.0 / Size * 100) >= 75.0)
BEGIN
	SET @Subject = @@ServerName + ' TempDb ALERT';
	
	SET @Body = '<html><head><style>' +
				'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
				'</style></head>' +
				'<body><h2>TempDb Usage</h2><hr><hr>' +
				'<table cellpadding=0 cellspacing=0 border=0>' +
				'<tr><td align=center bgcolor=#E6E6FA><b>TempDbSize_MB</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>FreeSpace_MB</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>FreeSpace_%</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>VersionStore_MB</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>InternalObjects_MB</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>UserObjects_MB</b></td>'+
				'</tr>';
				
	SELECT @Body += (
		SELECT	td= TotalSpaceInMB,'',
				td= FreeSpaceInMB,'',	
				td= TRY_CONVERT(NUMERIC(9,1),FreeSpaceInMB * 1.0 / TotalSpaceInMB * 100),'',
				td= VersionStoreSpaceInMB,'',		
				td= InternalObjSpaceInMB,'',
				td= UserObjSpaceInMB,''
		FROM  @TempDbUsage
		For XML RAW('tr'), ELEMENTS
	);

	SET @Body += '</table><hr><hr>';
	
	SET @Body += '<h2>TempDb User Objects</h2><hr><hr><table cellpadding=0 cellspacing=0 border=0>' +
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
		WHERE row_id <= 5
		For XML RAW('tr'), ELEMENTS
	);

	SET @Body += '</table><hr><hr>';
	
	SET @Body += '<h2>TempDb Version Store</h2><hr><hr><table cellpadding=0 cellspacing=0 border=0>' +
				'<tr><td align=center bgcolor=#E6E6FA><b>DatabaseName</b></td>' +
				'<td align=center bgcolor=#E6E6FA><b>Reserved_MB</b></td>'+
				'</tr>';
				
	SELECT @Body += (
		SELECT TOP(5)
				td= DB_NAME(database_id),'',
				td= TRY_CONVERT(INT,reserved_page_count * 1.0 / 128),''
		FROM sys.dm_tran_version_store_space_usage
		ORDER BY 3 desc
		For XML RAW('tr'), ELEMENTS
	);

	SET @Body += '</table><hr><hr>';

	SET @Body += '<h2>TempDb File Size and Space Used</h2><hr><hr><table cellpadding=0 cellspacing=0 border=0>' +
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