SET SESSION AUTHORIZATION 'opportunity';

SELECT SESSION_USER, CURRENT_USER;

-- SOME SQL

RESET SESSION AUTHORIZATION;



SET ROLE some_role;

-- SOME SQL

RESET ROLE;
SELECT
    inet_server_addr()      AS server_ip,
    inet_server_port()      AS server_port,
    current_setting('server_version') AS server_version,
    pg_is_in_recovery()     AS is_reader;