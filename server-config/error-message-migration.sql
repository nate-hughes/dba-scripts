
/********** SQL Server 2000 **********
select 'exec sp_addmessage @msgnum=' + CONVERT(varchar(30),message_id)
		+ ', @severity=' + CONVERT(varchar(30),severity)
		+ ', @msgtext=' + '''' + REPLACE([text], CHAR(ASCII('''')), CHAR(ASCII(''''))+CHAR(ASCII(''''))) + ''''
		+ ', @replace=''replace'';'
from sys.messages
where message_id >= 50000
********** SQL Server 2000 **********/

/********** SQL Server 2005+ **********/
---- identify missing error messages -- 
--select	'exec sp_addmessage @msgnum = ' + CONVERT(varchar(30),s.message_id)
--		+ ', @severity = ' + CONVERT(varchar(30),s.severity)
--		+ ', @msgtext = ' + '''' + REPLACE(s.[text], CHAR(ASCII('''')), CHAR(ASCII(''''))+CHAR(ASCII(''''))) + ''''
--		+ ', @replace = ''replace' + ''''
--FROM   [SOURCE SERVER].master.sys.messages s
--       LEFT OUTER JOIN sys.messages t ON s.message_id = t.message_id
--WHERE  t.message_id IS NULL
--       AND s.message_id >= 50000;

-- script out all error messages -- 
select	'exec sp_addmessage @msgnum = ' + CONVERT(varchar(30),s.message_id)
		+ ', @severity = ' + CONVERT(varchar(30),s.severity)
		+ ', @msgtext = ' + '''' + REPLACE(s.[text], CHAR(ASCII('''')), CHAR(ASCII(''''))+CHAR(ASCII(''''))) + ''''
		+ ', @replace = ''replace' + ''''
FROM   master.sys.messages s
WHERE  s.message_id >= 50000;
/********** SQL Server 2005+ **********/
