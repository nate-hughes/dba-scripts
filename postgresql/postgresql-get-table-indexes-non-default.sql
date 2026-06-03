SELECT indexdef, indexname, *
FROM pg_indexes 
WHERE schemaname IN (
		'schema'
	)
	AND tablename IN (
		'tablename'
	)
	AND indexdef !~ 'btree \((subject\, event_time|event_time|event_id)\)$'
ORDER BY schemaname, tablename;
