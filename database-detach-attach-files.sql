USE master;
GO
SET NOCOUNT ON;
GO

DECLARE @OverrideDB sysname = 'DBName' -- leave NULL if you want to create scripts for ALL user databases
		,@ServerName sysname
		,@RebuildLogFile bit = 1; -- change to 1 to rebuild the log file

-- create attach statements
DECLARE	@tmp_AttachScript TABLE (
	DBName sysname
	,AttachScript VARCHAR(MAX)
	,Processed BIT DEFAULT 0
);

INSERT @tmp_AttachScript (DBName, AttachScript)
SELECT	name AS DBName
		,'CREATE DATABASE ' + name + ' ON '
FROM    sys.databases
WHERE   name NOT IN ('master', 'model', 'msdb', 'tempdb', 'Resource', 'distribution', 'reportserver'
                    ,'reportservertempdb')
AND		(@OverrideDB IS NULL OR name = @OverrideDB);

DECLARE @sql NVARCHAR(MAX)
		,@DBName sysname;

DECLARE @tmp_DBFiles TABLE (
	data_space_id INT
	,physical_name NVARCHAR(260)
);

WHILE EXISTS (SELECT 1 FROM @tmp_AttachScript WHERE Processed = 0)
BEGIN
	SELECT	@DBName = DBName
	FROM	@tmp_AttachScript
	WHERE	Processed = 0;
	
	DELETE	
	FROM	@tmp_DBFiles;

    SET @sql = N'SELECT	data_space_id, physical_name FROM ' + @DBName + '.sys.database_files;'

	INSERT @tmp_DBFiles (data_space_id, physical_name)
	EXEC sys.sp_executesql @sql;

	UPDATE	upd
	SET		upd.AttachScript = upd.AttachScript + f.filelist
	FROM	@tmp_AttachScript upd
			INNER JOIN (
				SELECT	src.DBName
					,STUFF((
					SELECT	',( filename' + ' = N''' + physical_name + ''' )'
					FROM	@tmp_DBFiles tbl
					FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,'') AS filelist
				FROM	(
							SELECT	*
							FROM	@tmp_AttachScript
							WHERE	DBName = @DBName
						) src
			) f ON upd.DBName = f.DBName;	

	IF @RebuildLogFile = 1
		UPDATE	@tmp_AttachScript
		SET		AttachScript += ' FOR ATTACH_REBUILD_LOG'
		WHERE	DBName = @DBName;	

	UPDATE	@tmp_AttachScript
	SET		AttachScript += ';
				GO 
				ALTER AUTHORIZATION ON DATABASE::[' + @DBName + '] TO [sa];
				ALTER DATABASE ' + @DBName + ' SET TRUSTWORTHY ON;
				GO'
			,Processed = 1
	WHERE	DBName = @DBName;
END;

-- create detach statements
SELECT  'ALTER DATABASE ' + name + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; EXEC sys.sp_detach_db ''' + name + ''', ''true'';
		GO' AS DetachScript
		,name AS DBName
FROM    sys.databases
WHERE   name NOT IN ('master', 'model', 'msdb', 'tempdb', 'Resource', 'distribution', 'reportserver'
                    ,'reportservertempdb')
AND		(@OverrideDB IS NULL OR name = @OverrideDB)
UNION ALL
SELECT	AttachScript
		,DBName
FROM	@tmp_AttachScript
ORDER BY 2, 1;


