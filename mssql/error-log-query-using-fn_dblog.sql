SELECT [Operation], COUNT(*)
  FROM sys.fn_dblog(NULL, NULL) 
  GROUP BY [Operation]
  ORDER BY [Operation];
  