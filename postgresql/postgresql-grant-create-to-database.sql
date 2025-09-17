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

    -- Grant CREATE (DDL) on schema
    EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', schemaname, username);
END $$;
