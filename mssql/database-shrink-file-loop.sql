SET NOCOUNT ON;

USE ApplicationProcessor;
GO
-- SELECT * FROM sys.sysfiles;

DECLARE @sql VARCHAR(8000)
		,@name sysname = 'ApplicationProcessor' -- database file to shrink
		,@sizeMB INT
		,@usedMB INT
		,@freeMB INT = 321289 -- desired free space in MB after shrink
		,@shrinkMB INT = 512 -- increment to shrink file by in MB
		,@startRun datetime
		,@endRun datetime;

-- select (425-285) * 1024, 10240 / 512, 324238 - 10240

-- Get current file size in MB
SELECT @sizeMB = [size] / 128. FROM sys.sysfiles WHERE [name] = @name;

-- Get current space used in MB
SELECT @usedMB = FILEPROPERTY( @name, 'SpaceUsed' ) / 128.;
SELECT [StartFileSize] = @sizeMB, [StartUsedSpace] = @usedMB, [File] = @name;
/*
StartFileSize	StartUsedSpace	File
4,546,560	    14,509	        FLRA30.FLRA30
523,385	        2,872	        MFDM.MFDM
594,671	        223,066	        MFDW.odsIndex
*/

-- Loop until file at desired size
WHILE  @sizeMB >= @usedMB + @freeMB + @shrinkMB
BEGIN
	SELECT @sql = 'DBCC SHRINKFILE ( ' + @name + ', ' + CONVERT(VARCHAR(20), @sizeMB - @shrinkMB) + ' ) ', @startRun = GETDATE();
	PRINT 'Start ' + @sql;
	EXECUTE ( @sql );
	SELECT @endRun = GETDATE();
	PRINT 'Done ' + @sql + ' ' + CONVERT(VARCHAR(20), DATEDIFF(SECOND, @startRun, @endRun)) + ' seconds';
	
	-- Get current file size in MB
	SELECT @sizeMB = SIZE/128. FROM sysfiles WHERE name = @name;
	-- Get current space used in MB
	SELECT @usedMB = FILEPROPERTY( @name, 'SpaceUsed') / 128.;
END;

SELECT [EndFileSize] = @sizeMB, [EndUsedSpace] = @usedMB, [File] = @name;

--SELECT (14755424 - 14396135) - 38000
--SELECT (594671 - 362735) / 1024
--SELECT 216814 * .5