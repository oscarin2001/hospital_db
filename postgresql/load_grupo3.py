"""
load_grupo3.py - Carga DIRECTA del dump PostgreSQL de Grupo 3 a hospital_db.

Lee el archivo 'grupo3/clinica_db_completa 1.sql', parsea los bloques COPY
y los inserta en PostgreSQL usando psycopg2.copy_expert.

NO usa SQLite. TODO es PostgreSQL nativo.

Ademas crea registros en paciente/personal a partir de persona
(separacion de roles para 3NF).
"""

import os
import sys
import io

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("ERROR: pip install psycopg2-binary")
    sys.exit(1)

# ==============================================================
# CONFIGURACION
# ==============================================================
PG_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "hospital_db",
    "user": "postgres",
    "password": "1379"
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DUMP_PATH = os.path.join(BASE_DIR, "grupo3", "clinica_db_completa 1.sql")

# Tablas de Grupo 3 y sus columnas en el dump
# persona tiene id_especialidad en el dump, pero NO en nuestro esquema 3NF
TABLAS_GRUPO3 = {
    "zona": ["id_zona", "nombre", "ciudad"],
    "especialidad": ["id_especialidad", "nombre"],
    "tipo_diagnostico": ["id_tipo_diagnostico", "nombre", "categoria"],
    "persona": ["id_persona", "ci", "nombre", "fecha_nacimiento", "sexo",
                "direccion", "telefono", "matricula", "id_zona", "id_especialidad"],
    "horario_medico": ["id_horario", "dia_semana", "hora_inicio", "hora_fin",
                       "cupo_maximo", "id_persona"],
    "cita_medica": ["id_cita", "fecha_registro", "fecha_cita", "hora",
                    "numero_turno", "estado", "id_paciente", "id_medico"],
    "diagnostico": ["id_diagnostico", "descripcion", "observaciones",
                    "tipo_procedimiento", "id_cita", "id_tipo_diagnostico"],
    "receta": ["id_receta", "medicamentos", "indicaciones", "id_diagnostico"],
}

# Columnas de persona en NUESTRO esquema (sin id_especialidad)
PERSONA_COLS_DESTINO = ["id_persona", "ci", "nombre", "fecha_nacimiento", "sexo",
                        "direccion", "telefono", "matricula", "id_zona"]


def parse_copy_blocks(dump_path):
    """Parsea el dump PG y extrae bloques COPY como diccionarios {tabla: datos_tsv}."""
    blocks = {}
    current_table = None
    current_data = []

    with open(dump_path, "r", encoding="utf-8") as f:
        for line in f:
            # Detectar inicio de COPY
            if line.startswith("COPY public."):
                # COPY public.tabla (col1, col2...) FROM stdin;
                parts = line.split("(")[0]  # "COPY public.tabla "
                table_name = parts.replace("COPY public.", "").strip()
                if table_name in TABLAS_GRUPO3:
                    current_table = table_name
                    current_data = []
                continue

            # Detectar fin de COPY
            if line.strip() == "\\.":
                if current_table and current_data:
                    blocks[current_table] = current_data
                current_table = None
                current_data = []
                continue

            # Acumular datos
            if current_table:
                current_data.append(line)

    return blocks


def load_table_copy(cursor, table_name, columns, data_lines):
    """Carga datos usando COPY FROM STDIN (mas rapido que INSERT)."""
    cols_str = ", ".join(columns)
    copy_sql = f"COPY {table_name} ({cols_str}) FROM STDIN"

    data_buffer = io.StringIO("".join(data_lines))
    cursor.copy_expert(copy_sql, data_buffer)
    return len(data_lines)


def load_persona_special(cursor, data_lines):
    """
    Carga persona SIN id_especialidad (3NF).
    Retorna dict {id_persona: id_especialidad} para crear personal despues.
    """
    persona_esp_map = {}  # id_persona -> id_especialidad
    clean_lines = []

    for line in data_lines:
        fields = line.rstrip("\n").split("\t")
        if len(fields) != 10:
            continue

        id_persona = int(fields[0])
        id_especialidad = fields[9]  # puede ser \N (NULL)

        if id_especialidad != "\\N" and id_especialidad.strip():
            persona_esp_map[id_persona] = int(id_especialidad)

        # Construir linea sin id_especialidad (primeros 9 campos)
        clean_line = "\t".join(fields[:9]) + "\n"
        clean_lines.append(clean_line)

    # Cargar con COPY
    cols_str = ", ".join(PERSONA_COLS_DESTINO)
    copy_sql = f"COPY persona ({cols_str}) FROM STDIN"
    data_buffer = io.StringIO("".join(clean_lines))
    cursor.copy_expert(copy_sql, data_buffer)

    return len(clean_lines), persona_esp_map


def create_roles(cursor, persona_esp_map):
    """Crea registros en paciente y personal a partir de persona."""

    # Obtener todas las personas
    cursor.execute("SELECT id_persona, matricula FROM persona")
    personas = cursor.fetchall()

    pacientes = []
    personales = []

    for id_persona, matricula in personas:
        if matricula and matricula.strip():
            # Es medico -> va a personal
            esp_id = persona_esp_map.get(id_persona)
            # id_cargo=1 (Medico), id_turno=1 (Manana), id_estado=1 (Disponible) como defaults
            personales.append((id_persona, esp_id, 1, 1, 1))
        else:
            # Es paciente -> va a paciente
            pacientes.append((id_persona,))

    if pacientes:
        psycopg2.extras.execute_batch(cursor, """
            INSERT INTO paciente (id_persona) VALUES (%s) ON CONFLICT DO NOTHING
        """, pacientes, page_size=1000)

    if personales:
        psycopg2.extras.execute_batch(cursor, """
            INSERT INTO personal (id_persona, id_especialidad, id_cargo, id_turno, id_estado_disponibilidad)
            VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING
        """, personales, page_size=1000)

    return len(pacientes), len(personales)


def main():
    print("=" * 60)
    print("CARGA DIRECTA: Grupo 3 -> PostgreSQL")
    print("=" * 60)

    if not os.path.exists(DUMP_PATH):
        print(f"\nERROR: No se encontro el dump de Grupo 3:")
        print(f"  {DUMP_PATH}")
        sys.exit(1)

    # Conectar
    print(f"\n[1] Conectando a PostgreSQL: {PG_CONFIG['dbname']}")
    conn = psycopg2.connect(**PG_CONFIG)
    conn.autocommit = False
    cursor = conn.cursor()

    # Crear esquema
    print("[2] Creando esquema 3NF...")
    schema_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "schema_pg.sql")
    with open(schema_path, "r", encoding="utf-8") as f:
        cursor.execute(f.read())
    conn.commit()
    print("    Esquema creado.")

    # Parsear dump
    print("[3] Parseando dump de Grupo 3...")
    blocks = parse_copy_blocks(DUMP_PATH)
    print(f"    Tablas encontradas: {list(blocks.keys())}")

    # Cargar catalogos primero (necesarios para los seeds de Grupo 2)
    print("[4] Cargando catalogos Grupo 2...")
    catalogos = [
        ("cat_genero", [("Masculino",), ("Femenino",), ("No binario",)]),
        ("cat_cargo", [("Medico",), ("Enfermeria",), ("Recepcion",), ("Laboratorio",), ("Farmacia",), ("Administracion",)]),
        ("cat_turno", [("Manana",), ("Tarde",), ("Noche",)]),
        ("cat_estado_disponibilidad", [("Disponible",), ("Ocupado",), ("Ausente",), ("Vacaciones",)]),
        ("cat_gravedad", [("Leve",), ("Moderada",), ("Severa",), ("Critica",)]),
        ("cat_estado_cita", [("Agendada",), ("Atendida",), ("Cancelada",), ("No asistio",)]),
        ("cat_metodo_pago", [("Efectivo",), ("Tarjeta",), ("Transferencia",), ("Seguro",)]),
        ("cat_estado_pago", [("Pendiente",), ("Pagado",), ("Rechazado",), ("Anulado",)]),
        ("cat_tipo_registro", [("Ingreso",), ("Alta",), ("Observacion",), ("Evolucion",)]),
    ]
    for tabla, datos in catalogos:
        psycopg2.extras.execute_batch(cursor, f"INSERT INTO {tabla} (nombre) VALUES (%s) ON CONFLICT DO NOTHING", datos)
    conn.commit()
    print("    Catalogos cargados.")

    # Cargar procedimientos y medicamentos (Grupo 2)
    print("[5] Cargando procedimientos y medicamentos...")
    procedimientos = [
        ("Radiografia", 120.00, 20), ("Electrocardiograma", 150.00, 25),
        ("Ecografia", 200.00, 30), ("Sutura menor", 80.00, 15),
        ("Curacion avanzada", 60.00, 20), ("Tomografia", 550.00, 45),
        ("Resonancia", 900.00, 60), ("Laboratorio completo", 180.00, 35),
    ]
    psycopg2.extras.execute_batch(cursor,
        "INSERT INTO procedimiento_medico (nombre, costo_base, tiempo_estimado_min) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
        procedimientos)

    medicamentos = [
        ("Paracetamol 500mg", 3000, 1.20), ("Ibuprofeno 400mg", 2500, 1.50),
        ("Amoxicilina 500mg", 1800, 2.80), ("Omeprazol 20mg", 2200, 1.90),
        ("Loratadina 10mg", 1500, 1.10), ("Metformina 850mg", 1200, 2.40),
        ("Losartan 50mg", 1300, 2.20), ("Atorvastatina 20mg", 900, 3.00),
        ("Salbutamol inhalador", 500, 8.50), ("Diclofenaco 50mg", 1400, 1.70),
        ("Azitromicina 500mg", 700, 4.20), ("Cefalexina 500mg", 900, 3.10),
    ]
    psycopg2.extras.execute_batch(cursor,
        "INSERT INTO medicamento (nombre_medicamento, stock_actual, costo_unitario) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
        medicamentos)
    conn.commit()
    print("    Procedimientos y medicamentos cargados.")

    # Cargar tablas de Grupo 3 en orden de FK
    print("[6] Cargando datos de Grupo 3...\n")
    total = 0
    persona_esp_map = {}

    # Orden de carga (padres antes que hijos)
    orden = ["zona", "especialidad", "tipo_diagnostico", "persona",
             "horario_medico", "cita_medica", "diagnostico", "receta"]

    for tabla in orden:
        if tabla not in blocks:
            print(f"  {tabla}: sin datos en dump")
            continue

        data = blocks[tabla]

        if tabla == "persona":
            # Caso especial: quitar id_especialidad para 3NF
            count, persona_esp_map = load_persona_special(cursor, data)
        else:
            cols = TABLAS_GRUPO3[tabla]
            count = load_table_copy(cursor, tabla, cols, data)

        conn.commit()
        total += count
        print(f"  {tabla}: {count:,} filas")

    # Crear roles (paciente/personal) desde persona
    print(f"\n[7] Creando roles paciente/personal...")
    n_pac, n_per = create_roles(cursor, persona_esp_map)
    conn.commit()
    print(f"    Pacientes: {n_pac:,}")
    print(f"    Personal: {n_per:,}")

    # Actualizar secuencias
    print("\n[8] Actualizando secuencias...")
    secuencias = [
        ("zona", "id_zona"), ("especialidad", "id_especialidad"),
        ("tipo_diagnostico", "id_tipo_diagnostico"), ("persona", "id_persona"),
        ("horario_medico", "id_horario"), ("cita_medica", "id_cita"),
        ("diagnostico", "id_diagnostico"), ("receta", "id_receta"),
        ("paciente", "id_paciente"), ("personal", "id_personal"),
        ("cat_genero", "id_genero"), ("cat_cargo", "id_cargo"),
        ("cat_turno", "id_turno"), ("cat_estado_disponibilidad", "id_estado_disponibilidad"),
        ("cat_gravedad", "id_gravedad"), ("cat_estado_cita", "id_estado_cita"),
        ("cat_metodo_pago", "id_metodo_pago"), ("cat_estado_pago", "id_estado_pago"),
        ("cat_tipo_registro", "id_tipo_registro"),
        ("procedimiento_medico", "id_procedimiento"), ("medicamento", "id_medicamento"),
        ("pago", "id_pago"), ("diagnostico_procedimiento", "id_diag_proc"),
        ("historial_clinico", "id_historial"), ("receta_detalle", "id_receta_detalle"),
    ]
    for tabla, col in secuencias:
        try:
            cursor.execute(f"""
                SELECT setval(pg_get_serial_sequence('{tabla}', '{col}'),
                       COALESCE((SELECT MAX({col}) FROM {tabla}), 1))
            """)
        except Exception:
            conn.rollback()
    conn.commit()
    print("    Secuencias actualizadas.")

    # Resumen
    print(f"\n{'=' * 60}")
    print("CARGA GRUPO 3 COMPLETADA")
    print(f"{'=' * 60}")

    cursor.execute("""
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name
    """)
    for (tbl,) in cursor.fetchall():
        cursor.execute(f"SELECT COUNT(*) FROM {tbl}")
        cnt = cursor.fetchone()[0]
        if cnt > 0:
            print(f"  {tbl}: {cnt:,}")

    conn.close()
    print("\nCarga de Grupo 3 exitosa!")


if __name__ == "__main__":
    main()
