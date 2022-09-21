-- create new role
CREATE ROLE readonly;

-- grant access to all existing tables
GRANT CONNECT ON DATABASE mydatabase TO readonly;
GRANT USAGE ON SCHEMA myschema TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA myschema TO readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA myschema TO readonly;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA myschema TO readonly;

-- grant access to all table which will be created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT SELECT ON TABLES TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT SELECT ON SEQUENCES TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema GRANT EXECUTE ON FUNCTIONS TO readonly;

-- create user and grant role to this user
CREATE USER myuser WITH PASSWORD 'xxxxxxxx';
GRANT readonly TO myuser;
