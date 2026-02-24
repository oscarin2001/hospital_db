"""
setup_postgresql.py - Script maestro para crear la BD hospital completa.

Flujo:
  1. Verifica dependencias Python (psycopg2, faker)
  2. Verifica que PostgreSQL 17 este corriendo
  3. Crea la base de datos 'hospital_db'
  4. Carga datos de Grupo 3 (dump PostgreSQL directo, sin SQLite)
  5. Genera datos propios con Faker (nuestro grupo)
  6. Muestra instrucciones de conexion

Requisitos:
  - PostgreSQL 17 corriendo (net start postgresql-x64-17)
  - pip install psycopg2-binary faker

Uso:
  cd C:\\Users\\oscar\\Desktop\\db
  python postgresql/setup_postgresql.py
"""

import subprocess
import sys
import os

# ==============================================================
# CONFIGURACION
# ==============================================================
PG_PASSWORD = "1379"
PG_USER = "postgres"
PG_HOST = "localhost"
PG_PORT = "5432"
PG_DB = "hospital_db"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PG_DIR = os.path.join(BASE_DIR, "postgresql")


def run(cmd, check=True, env=None):
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, env=merged_env)
    if check and result.returncode != 0:
        return None, result.stderr
    return result.stdout.strip(), None


def check_dependencies():
    print("\n[1/5] Verificando dependencias Python...")
    missing = []
    try:
        import psycopg2
        print("  psycopg2: OK")
    except ImportError:
        missing.append("psycopg2-binary")
    try:
        from faker import Faker
        print("  Faker: OK")
    except ImportError:
        missing.append("faker")
    if missing:
        print(f"  Instalando: {', '.join(missing)}...")
        subprocess.run([sys.executable, "-m", "pip", "install"] + missing, check=True)


def check_postgresql():
    print(f"\n[2/5] Verificando PostgreSQL en puerto {PG_PORT}...")

    # Agregar PG al PATH si no esta
    pg_bin = r"C:\Program Files\PostgreSQL\17\bin"
    if os.path.exists(pg_bin) and pg_bin not in os.environ.get("PATH", ""):
        os.environ["PATH"] = pg_bin + ";" + os.environ.get("PATH", "")

    out, _ = run("psql --version")
    if out is None:
        print("\n  ERROR: PostgreSQL NO esta en el PATH.")
        print(f"  Agrega: $env:Path += \";{pg_bin}\"")
        sys.exit(1)
    print(f"  {out}")

    out, _ = run(f"pg_isready -h {PG_HOST} -p {PG_PORT}")
    if out is None or "accepting" not in (out or ""):
        print(f"\n  ERROR: PostgreSQL NO esta corriendo en {PG_HOST}:{PG_PORT}")
        print("  Abre PowerShell como ADMINISTRADOR y ejecuta:")
        print("    net start postgresql-x64-17")
        sys.exit(1)
    print(f"  PostgreSQL corriendo en {PG_HOST}:{PG_PORT}")


def create_database():
    print(f"\n[3/5] Creando base de datos '{PG_DB}'...")
    pg_env = {"PGPASSWORD": PG_PASSWORD}

    out, _ = run(
        f'psql -U {PG_USER} -h {PG_HOST} -p {PG_PORT} -tc '
        f"\"SELECT 1 FROM pg_database WHERE datname='{PG_DB}'\"",
        env=pg_env)

    if out and "1" in out:
        print(f"  Base '{PG_DB}' ya existe. Eliminando y recreando...")
        run(f'psql -U {PG_USER} -h {PG_HOST} -p {PG_PORT} -c '
            f"\"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='{PG_DB}' AND pid <> pg_backend_pid();\"",
            env=pg_env, check=False)
        run(f'psql -U {PG_USER} -h {PG_HOST} -p {PG_PORT} -c "DROP DATABASE {PG_DB};"', env=pg_env)

    out, err = run(f'psql -U {PG_USER} -h {PG_HOST} -p {PG_PORT} -c "CREATE DATABASE {PG_DB};"', env=pg_env)
    if err and "already exists" not in (err or ""):
        print(f"  Error: {err}")
        sys.exit(1)
    print(f"  Base de datos '{PG_DB}' lista.")


def run_load_grupo3():
    print("\n[4/5] Cargando datos de Grupo 3 (PostgreSQL directo)...")
    script = os.path.join(PG_DIR, "load_grupo3.py")
    result = subprocess.run([sys.executable, script], cwd=BASE_DIR)
    if result.returncode != 0:
        print("  ERROR en la carga de Grupo 3.")
        sys.exit(1)


def run_populate():
    print("\n[5/5] Generando datos propios con Faker...")
    script = os.path.join(PG_DIR, "populate_db_pg.py")
    result = subprocess.run([sys.executable, script], cwd=BASE_DIR)
    if result.returncode != 0:
        print("  ERROR en populate.")
        sys.exit(1)


def main():
    print("=" * 60)
    print("SETUP COMPLETO: BD HOSPITAL -> PostgreSQL 17")
    print("=" * 60)
    print(f"  BD: {PG_DB} | Host: {PG_HOST}:{PG_PORT}")
    print(f"  User: {PG_USER} | Password: {PG_PASSWORD}")

    check_dependencies()
    check_postgresql()
    create_database()
    run_load_grupo3()
    run_populate()

    print("\n" + "=" * 60)
    print("SETUP COMPLETADO EXITOSAMENTE!")
    print("=" * 60)
    print(f"""
CONEXION:
  Host:       {PG_HOST}
  Puerto:     {PG_PORT}
  Base:       {PG_DB}
  Usuario:    {PG_USER}
  Contrasena: {PG_PASSWORD}

INTERFAZ WEB (pgweb):
  .\\pgweb_windows_amd64.exe --bind=0.0.0.0 --listen=5000 --host={PG_HOST} --user={PG_USER} --pass={PG_PASSWORD} --db={PG_DB}
  Abrir: http://localhost:5000

ALTERNATIVA (pgAdmin 4):
  Ya instalado con PostgreSQL 17. Menu inicio -> pgAdmin 4

TERMINAL (psql):
  $env:PGPASSWORD="{PG_PASSWORD}"; psql -U {PG_USER} -d {PG_DB}

PYTHON:
  import psycopg2
  conn = psycopg2.connect(host='{PG_HOST}', dbname='{PG_DB}', user='{PG_USER}', password='{PG_PASSWORD}')
""")


if __name__ == "__main__":
    main()
