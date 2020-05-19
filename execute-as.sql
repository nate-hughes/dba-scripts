
--Display current execution context
SELECT SUSER_NAME(), USER_NAME();  

--Scope of impersonation is at the server level
EXECUTE AS LOGIN = 'SomeLogin';
----Scope of impersonation is restricted to the current database
--EXECUTE AS USER = 'SomeLogin';

--Display current execution context
SELECT SUSER_NAME(), USER_NAME();  

--Command to be ran under impersonation
[COPY COMMAND HERE]

--Reset the execution context
REVERT;

--Display current execution context
SELECT SUSER_NAME(), USER_NAME();  
