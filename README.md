# hospital_db

Breve guía para que otros instalen y ejecuten la base de datos localmente.

- Cambiar la contraseña de PostgreSQL (si es distinta): buscar y actualizar la cadena `1379` en:
  - `postgresql/setup_postgresql.py`
  - `postgresql/load_grupo3.py`
  - `postgresql/populate_db_pg.py`

- Iniciar el servicio PostgreSQL (PowerShell como Administrador):
  ```powershell
  net start postgresql-x64-17
  ```

- Ejecutar el setup (desde la carpeta del proyecto):
  ```powershell
  cd C:\Users\oscar\Desktop\db
  python postgresql/setup_postgresql.py
  ```

- Acceder a la BD con `psql` (ejemplo desde la carpeta bin de PostgreSQL):
  ```powershell
  $env:PGPASSWORD = "TU_CONTRASENA"
  "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d hospital_db
  ```

- Exportar la base de datos (opcional):
  ```powershell
  "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -U postgres -d hospital_db -F c -f ..\backup_hospital.dump
  ```

Notas:
- Si no quieren ejecutar el script completo, pueden importar el `backup_hospital.dump` con `pg_restore`.
- El script `postgresql/schema.dbml` contiene el diagrama DBML para `dbdiagram.io`.

Orden de ejecución (pasos recomendados)
-----------------------------------
1. Iniciar el servicio PostgreSQL (PowerShell como Administrador):
  ```powershell
  net start postgresql-x64-17
  ```
2. Verificar/actualizar la contraseña en los scripts si tu postgres usa otra (buscar `1379`).
3. Desde la carpeta del proyecto ejecutar el script maestro:
  ```powershell
  cd C:\Users\oscar\Desktop\db
  python postgresql/setup_postgresql.py
  ```
4. Verificar la base cargada con `psql` o pgAdmin.
5. (Opcional) Generar un volcado con `pg_dump` para compartir:
  ```powershell
  "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -U postgres -d hospital_db -F c -f ..\backup_hospital.dump
  ```

Eso es todo: el script crea la BD, importa Grupo 3, y genera nuestros datos con Faker.
