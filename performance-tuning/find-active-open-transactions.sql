-- Find active open transactions

SELECT  est.session_id     AS [Session ID]
       ,est.transaction_id AS [Transaction ID]
       ,tas.name           AS [Transaction Name]
       ,tds.database_id    AS [Database ID]
FROM    sys.dm_tran_active_transactions              tas
        INNER JOIN sys.dm_tran_database_transactions tds
            ON (tas.transaction_id = tds.transaction_id)
        INNER JOIN sys.dm_tran_session_transactions  est
            ON (est.transaction_id = tas.transaction_id)
WHERE   est.is_user_transaction = 1 -- user
AND     tas.transaction_state = 2 -- active
AND     tds.database_transaction_begin_time IS NOT NULL;
-- Time at which the database became involved in the transaction, You can apply filter here
