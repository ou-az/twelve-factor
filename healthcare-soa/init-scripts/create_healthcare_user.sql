-- Create healthcare_user if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'healthcare_user') THEN
    CREATE USER healthcare_user WITH PASSWORD 'healthcare_password';
  END IF;
END
$$;

-- Grant permissions on patient database
GRANT ALL PRIVILEGES ON DATABASE healthcare_patient TO healthcare_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO healthcare_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO healthcare_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO healthcare_user;

-- Grant permissions on appointment database
GRANT ALL PRIVILEGES ON DATABASE healthcare_appointment TO healthcare_user;
