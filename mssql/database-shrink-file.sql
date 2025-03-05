USE [Database]
GO

DECLARE	@StartSize INT = 102400 -- SET START SIZE OF THE DATABASE FILE (MB)
		,@TargetSize INT = 20480  -- SET END SIZE OF THE DATABASE FILE (MB)
;

WHILE @StartSize > @TargetSize
BEGIN
	SET @StartSize = @StartSize - 10240;
    DBCC SHRINKFILE (N'FileName' , @StartSize); -- logical name
END;
GO
