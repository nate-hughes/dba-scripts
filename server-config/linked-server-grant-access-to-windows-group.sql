USE master;
GO

DECLARE @LinkedServerName NVARCHAR(128) = N'<linked server name>'
       ,@RemoteUser       NVARCHAR(128) = N'<sql login>'
       ,@RemotePwd        NVARCHAR(128) = N'<sql login password>'
       ,@WindowsGroupName NVARCHAR(128) = N'<windows group name>';

-- drop table #LoginsList
CREATE TABLE #LoginsList (
    [Account Name]      NVARCHAR(128)
   ,Type                NVARCHAR(128)
   ,Privilege           NVARCHAR(128)
   ,[Mapped Login Name] NVARCHAR(128)
   ,[Permission Path]   NVARCHAR(128)
);

INSERT  #LoginsList ([Account Name], Type, Privilege, [Mapped Login Name], [Permission Path])
EXEC sys.xp_logininfo @acctname = @WindowsGroupName, @option = 'members';

SELECT  'EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N''' + @LinkedServerName + ''', @locallogin = N'''
        + [Account Name] + ''', @useself = N''False'', @rmtuser = N''' + @RemoteUser + ''', @rmtpassword = N'''
        + @RemotePwd + ''';'
FROM    #LoginsList;
