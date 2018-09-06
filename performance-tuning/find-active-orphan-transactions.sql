SELECT  des.session_id
       ,des.login_time
       ,des.last_request_start_time
       ,des.last_request_end_time
       ,des.host_name
       ,des.login_name
FROM    sys.dm_exec_sessions                        des
        INNER JOIN sys.dm_tran_session_transactions dtst
            ON des.session_id = dtst.session_id
        LEFT JOIN sys.dm_exec_requests              der
            ON dtst.session_id = der.session_id
WHERE   der.session_id IS NULL
ORDER BY des.session_id;