/*
Who's Using the DAC?
http://www.sqlservercentral.com/articles/Dedicated+Administrator+Connection+(DAC)/174694/

Who’s Been Sleeping in My DAC? How to Tell Who’s using the Dedicated Admin Connection.
https://www.brentozar.com/archive/2011/08/dedicated-admin-connection-why-want-when-need-how-tell-whos-using/
*/

-- confirm DAC endpoint exists
select * from sys.endpoints where name = 'Dedicated Admin Connection';

-- see who's using it
SELECT CASE WHEN s.session_id= @@SPID THEN 'It''s me! '
			ELSE ''
		END + coalesce(s.login_name,'???') as WhosGotTheDAC ,
		s.session_id ,
		s.login_name ,
		s.nt_domain ,
		s.nt_user_name ,
		s.login_time ,
		s.host_name ,
		s.program_name ,
		s.status ,
		s.original_login_name
FROM	sys.dm_exec_sessions s
		INNER JOIN sys.endpoints e ON e.endpoint_id = s.endpoint_id 
WHERE	e.name='Dedicated Admin Connection';

