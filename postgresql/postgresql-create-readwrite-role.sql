-- create new role
CREATE ROLE readwrite;

-- grant access to all existing tables
GRANT CONNECT ON DATABASE mydatabase TO readwrite;
GRANT USAGE ON SCHEMA myschema TO readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA myschema TO readwrite;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA myschema TO readwrite;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA myschema TO readwrite;

-- grant access to all table which will be created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT USAGE ON SEQUENCES TO readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT EXECUTE ON FUNCTIONS TO readwrite;

-- create user and grant role to this user
CREATE USER myuser WITH PASSWORD 'xxxxxxxx';
GRANT readwrite TO myuser;
