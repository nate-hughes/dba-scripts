-- http://www.sqlfingers.com/2018/05/how-to-query-all-of-named-instances-for.html
-- how many instances are there?

DECLARE @Instances TABLE (
       Value VARCHAR(100),
       InstanceName VARCHAR(100),
       Data VARCHAR(100)
       )

INSERT @Instances
EXECUTE xp_regread
  @rootkey = 'HKEY_LOCAL_MACHINE',
  @key = 'SOFTWARE\Microsoft\Microsoft SQL Server',
  @value_name = 'InstalledInstances' 

-- return your data
SELECT InstanceName FROM @Instances