DECLARE @LinkedServers TABLE (name NVARCHAR(128), is_tested BIT DEFAULT 0);

INSERT @LinkedServers (name)
SELECT name FROM sys.servers WHERE is_linked = 1;

DECLARE @servername NVARCHAR(128);

WHILE EXISTS (SELECT 1 FROM @LinkedServers WHERE is_tested = 0)
BEGIN
BEGIN TRY
	SELECT	TOP 1
			@servername = name
	FROM	@LinkedServers
	WHERE	is_tested = 0;
	
	UPDATE	@LinkedServers
	SET		is_tested = 1
	WHERE	name = @servername;

	EXEC master.dbo.sp_testlinkedserver @server=@servername;
END TRY

BEGIN CATCH
	SELECT	@servername
			,ERROR_NUMBER()
			,ERROR_SEVERITY()
			,ERROR_STATE()
			,ERROR_PROCEDURE()
			,ERROR_LINE()
			,ERROR_MESSAGE();
END CATCH
END;