-- Make sure you are connected to the target database
-- Update the variable with the actual username
DO $$
DECLARE
    dbname text := current_database();
	schemaname text := 'public';
    username text := 'new_user';
BEGIN
	-- Database access
	EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I;', dbname, username);

    -- Grant USAGE on schema
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', schemaname, username);

    -- Grant on existing tables
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO %I;', schemaname, username);

    -- Grant on existing sequences
    EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA %I TO %I;', schemaname, username);

    -- Grant on existing functions (optional)
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I;', schemaname, username);

    -- Set default privileges for future tables
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I;', schemaname, username);

    -- Set default privileges for future sequences
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I;', schemaname, username);

    -- Set default privileges for future functions (optional)
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO %I;', schemaname, username);
END $$;
