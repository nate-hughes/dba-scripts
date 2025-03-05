SELECT name, is_disabled, LOGINPROPERTY(name, N'isLocked') as is_locked
FROM sys.sql_logins
WHERE LOGINPROPERTY(name, N'isLocked') = 1
ORDER BY name;