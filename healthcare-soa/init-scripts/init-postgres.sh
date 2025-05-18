#!/bin/bash
set -e

# Function to create databases
create_db() {
  local db=$1
  echo "Creating database: $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE $db;
    GRANT ALL PRIVILEGES ON DATABASE $db TO $POSTGRES_USER;
EOSQL
}

# Create each database
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
  echo "Creating multiple databases: $POSTGRES_MULTIPLE_DATABASES"
  for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
    create_db $db
  done
  echo "Multiple databases created"
fi

# Create tables for patient service
echo "Setting up tables for healthcare_patient database"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "healthcare_patient" <<-EOSQL
  CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    ssn VARCHAR(11) UNIQUE,
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    created_date DATE,
    last_modified_date DATE
  );
  
  -- Add some sample data
  INSERT INTO patients (first_name, last_name, date_of_birth, ssn, email, phone, address, city, state, zip_code, created_date, last_modified_date)
  VALUES 
  ('John', 'Doe', '1980-01-15', '123-45-6789', 'john.doe@example.com', '(555) 123-4567', '123 Main St', 'Springfield', 'IL', '62704', CURRENT_DATE, CURRENT_DATE),
  ('Jane', 'Smith', '1975-05-22', '987-65-4321', 'jane.smith@example.com', '(555) 987-6543', '456 Oak Ave', 'Springfield', 'IL', '62704', CURRENT_DATE, CURRENT_DATE)
  ON CONFLICT (ssn) DO NOTHING;
  
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
  GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_USER;
EOSQL

# Create tables for appointment service
echo "Setting up tables for healthcare_appointment database"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "healthcare_appointment" <<-EOSQL
  CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    patient_name VARCHAR(200) NOT NULL,
    provider_id BIGINT NOT NULL,
    provider_name VARCHAR(200) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    appointment_type VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'SCHEDULED',
    reason TEXT,
    notes_id VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
  );
  
  -- Add some sample appointments
  INSERT INTO appointments (patient_id, patient_name, provider_id, provider_name, start_time, end_time, appointment_type, status, reason, created_at, updated_at)
  VALUES 
  (1, 'John Doe', 101, 'Dr. Sarah Johnson', '2025-05-20 09:00:00', '2025-05-20 09:30:00', 'PHYSICAL', 'SCHEDULED', 'Annual checkup', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  (2, 'Jane Smith', 102, 'Dr. Robert Williams', '2025-05-21 14:00:00', '2025-05-21 14:45:00', 'CONSULTATION', 'SCHEDULED', 'Follow-up visit', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
  
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
  GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_USER;
EOSQL

echo "Database initialization completed successfully"
