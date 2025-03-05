/*
Remove Files From tempdb
https://www.sqlskills.com/blogs/erin/remove-files-from-tempdb/
*/

USE [tempdb];
GO
DBCC SHRINKFILE ([logicalname], EMPTYFILE);
GO
ALTER DATABASE [tempdb] REMOVE FILE [logicalname];
GO
