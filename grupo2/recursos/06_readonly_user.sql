-- Crear usuario solo-lectura para hospitaldb (LAN)
-- Rol: lector

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lector') THEN
    CREATE ROLE lector LOGIN PASSWORD 'lector123456';
  END IF;
END $$;

GRANT CONNECT ON DATABASE hospitaldb TO lector;
GRANT USAGE ON SCHEMA public TO lector;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lector;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lector;
REVOKE CREATE ON SCHEMA public FROM lector;

COMMIT;
