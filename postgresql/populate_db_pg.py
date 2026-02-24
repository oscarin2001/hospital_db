"""
populate_db_pg.py - Genera datos con Faker y los inserta en PostgreSQL.
Agrega datos ENCIMA de los existentes (Grupo 3) sin borrar nada.

Datos generados (nuestro grupo):
  - 9 especialidades adicionales
  - 10 zonas nuevas
  - ~330 medicos nuevos (con personal)
  - 30,000 pacientes nuevos
  - 50,000 citas medicas
  - Diagnosticos, recetas, pagos, historial clinico

Requisitos:
  pip install psycopg2-binary faker
"""

import sys
import random
from datetime import timedelta

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("ERROR: pip install psycopg2-binary")
    sys.exit(1)

from faker import Faker

fake = Faker('es_ES')
random.seed(42)

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

conn = psycopg2.connect(**PG_CONFIG)
conn.autocommit = False
cursor = conn.cursor()

print("=" * 60)
print("POPULATE: Datos propios con Faker -> PostgreSQL")
print("=" * 60)

# ==============================================================
# 1. AGREGAR ESPECIALIDADES FALTANTES
# ==============================================================
print("\n[1/10] Agregando especialidades faltantes...")

especialidades_nuevas = [
    "Medicina Interna", "Cirugia General", "Radiologia", "Anestesiologia",
    "Nefrologia", "Hematologia", "Reumatologia", "Infectologia",
    "Medicina Familiar"
]

for esp in especialidades_nuevas:
    cursor.execute("SELECT COUNT(*) FROM especialidad WHERE nombre = %s", (esp,))
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO especialidad (nombre) VALUES (%s)", (esp,))
        print(f"  + {esp}")
conn.commit()

cursor.execute("SELECT id_especialidad, nombre FROM especialidad")
especialidades = {row[1]: row[0] for row in cursor.fetchall()}
especialidad_ids = list(especialidades.values())
print(f"  Total especialidades: {len(especialidades)}")

# ==============================================================
# 2. AGREGAR ZONAS ADICIONALES
# ==============================================================
print("\n[2/10] Agregando zonas adicionales...")
zonas_nuevas = [
    ("Villa Fatima", "La Paz"), ("Miraflores", "La Paz"), ("Sopocachi", "La Paz"),
    ("Calacoto", "La Paz"), ("Zona Sur", "Santa Cruz"), ("Barrio Lindo", "Santa Cruz"),
    ("Las Palmas", "Santa Cruz"), ("Hamacas Norte", "Cochabamba"), ("Cala Cala", "Cochabamba"),
    ("Queru Queru", "Cochabamba")
]

zonas_agregadas = 0
for nombre, ciudad in zonas_nuevas:
    cursor.execute("SELECT COUNT(*) FROM zona WHERE nombre = %s AND ciudad = %s", (nombre, ciudad))
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO zona (nombre, ciudad) VALUES (%s, %s)", (nombre, ciudad))
        zonas_agregadas += 1
conn.commit()

cursor.execute("SELECT id_zona FROM zona")
zona_ids = [row[0] for row in cursor.fetchall()]
print(f"  Zonas nuevas: {zonas_agregadas}, Total zonas: {len(zona_ids)}")

# ==============================================================
# DICCIONARIO DE ENFERMEDADES POR ESPECIALIDAD
# ==============================================================
enfermedades_por_especialidad = {
    "Medicina General": ["Resfriado comun", "Gripe estacional", "Infeccion urinaria", "Gastritis aguda",
        "Hipertension arterial leve", "Diabetes mellitus tipo 2", "Lumbalgia", "Cefalea tensional"],
    "Medicina Interna": ["Insuficiencia cardiaca", "Sepsis", "Insuficiencia respiratoria aguda",
        "Sindrome metabolico complicado", "Enfermedad hepatica avanzada", "Trombosis venosa profunda"],
    "Cardiologia": ["Infarto agudo de miocardio", "Angina inestable", "Arritmias complejas",
        "Miocardiopatia dilatada", "Valvulopatias severas", "Endocarditis infecciosa"],
    "Neurologia": ["Accidente cerebrovascular", "Epilepsia refractaria", "Esclerosis multiple",
        "Enfermedad de Parkinson avanzada", "Miastenia gravis", "Neuropatias severas"],
    "Pediatria": ["Sepsis neonatal", "Prematuridad extrema", "Bronquiolitis grave",
        "Cardiopatias congenitas", "Meningitis bacteriana", "Desnutricion severa"],
    "Ginecologia": ["Cancer de cuello uterino", "Cancer de ovario", "Miomatosis uterina complicada",
        "Endometriosis severa", "Enfermedad inflamatoria pelvica complicada"],
    "Traumatologia": ["Fracturas multiples", "Fractura expuesta", "Politraumatismo",
        "Lesion medular", "Luxaciones complejas", "Osteomielitis"],
    "Dermatologia": ["Psoriasis severa", "Lupus cutaneo", "Melanoma maligno",
        "Penfigo vulgar", "Dermatitis atopica grave"],
    "Oftalmologia": ["Glaucoma avanzado", "Desprendimiento de retina", "Catarata complicada",
        "Retinopatia diabetica proliferativa", "Queratitis severa"],
    "Otorrinolaringologia": ["Sinusitis complicada", "Otitis media cronica", "Perforacion timpanica",
        "Cancer de laringe", "Apnea obstructiva del sueno severa"],
    "Psiquiatria": ["Esquizofrenia", "Trastorno bipolar", "Depresion mayor severa",
        "Trastorno de ansiedad generalizada grave", "Psicosis aguda"],
    "Urologia": ["Insuficiencia renal obstructiva", "Litiasis renal complicada", "Cancer de prostata",
        "Cancer renal", "Hiperplasia prostatica severa"],
    "Endocrinologia": ["Cetoacidosis diabetica", "Hipertiroidismo severo", "Hipotiroidismo grave",
        "Crisis suprarrenal", "Acromegalia"],
    "Oncologia": ["Cancer de mama", "Cancer de pulmon", "Cancer gastrico",
        "Cancer colorrectal", "Metastasis multiples"],
    "Gastroenterologia": ["Ulcera gastrica perforada", "Enfermedad de Crohn", "Colitis ulcerosa",
        "Cirrosis hepatica", "Pancreatitis aguda", "Hepatitis cronica"],
    "Neumologia": ["Neumonia severa", "EPOC exacerbado", "Asma grave",
        "Fibrosis pulmonar", "Derrame pleural", "Tuberculosis pulmonar"],
    "Radiologia": ["Tumores detectados por imagen", "Hemorragias internas", "Fracturas complejas",
        "Tromboembolismo pulmonar", "Aneurismas"],
    "Anestesiologia": ["Manejo de dolor cronico severo", "Complicaciones anestesicas",
        "Shock perioperatorio", "Reacciones adversas a anestesicos"],
    "Cirugia General": ["Apendicitis complicada", "Peritonitis", "Obstruccion intestinal",
        "Hernia estrangulada", "Colecistitis aguda complicada"],
    "Nefrologia": ["Insuficiencia renal aguda", "Enfermedad renal cronica terminal",
        "Sindrome nefrotico", "Glomerulonefritis severa"],
    "Hematologia": ["Leucemia aguda", "Linfoma", "Mieloma multiple",
        "Anemia aplasica", "Trastornos de coagulacion severos"],
    "Reumatologia": ["Artritis reumatoide severa", "Lupus eritematoso sistemico",
        "Espondilitis anquilosante", "Vasculitis sistemica"],
    "Infectologia": ["Sepsis grave", "Shock septico", "Tuberculosis complicada",
        "VIH/SIDA avanzado", "Infecciones intrahospitalarias multirresistentes"],
    "Medicina Familiar": ["Hipertension arterial", "Diabetes mellitus", "Infecciones respiratorias",
        "Asma", "EPOC", "Obesidad"],
}

# ==============================================================
# 3. AGREGAR NUEVOS MEDICOS (persona + personal)
# ==============================================================
print("\n[3/10] Agregando medicos nuevos...")

nombres_m = ["Alejandro", "Fernando", "Roberto", "Gustavo", "Hector", "Manuel", "Raul", "Sergio",
             "Tomas", "Ivan", "Alberto", "Ernesto", "Hugo", "Ramon", "Francisco", "Gonzalo",
             "Martin", "Victor", "Arturo", "Enrique"]
nombres_f = ["Claudia", "Veronica", "Silvia", "Graciela", "Lorena", "Adriana", "Cecilia", "Carla",
             "Mariana", "Sandra", "Ximena", "Viviana", "Patricia", "Gloria", "Estela", "Norma",
             "Alicia", "Olga", "Nadia", "Irene"]
apellidos = ["Rodriguez", "Martinez", "Lopez", "Gonzalez", "Hernandez", "Perez", "Sanchez",
             "Ramirez", "Torres", "Flores", "Garcia", "Mendoza", "Rojas", "Vargas", "Castro",
             "Morales", "Gutierrez", "Reyes", "Diaz", "Aguilar", "Rivera", "Cruz", "Ortiz",
             "Delgado", "Espinoza", "Chavez", "Contreras", "Medina", "Ponce", "Salazar"]

medicos_persona = []
medicos_esp = []  # (indice_en_lista, esp_id)
ci_counter = 2000001

for esp_nombre, esp_id in especialidades.items():
    n_medicos = random.randint(10, 18)
    for _ in range(n_medicos):
        sexo = random.choice(['M', 'F'])
        nombre = random.choice(nombres_m if sexo == 'M' else nombres_f) + " " + \
                 random.choice(apellidos) + " " + random.choice(apellidos)
        ci = str(ci_counter); ci_counter += 1
        fecha_nac = fake.date_between(start_date='-60y', end_date='-28y')
        direccion = f"Calle {fake.street_name()} #{random.randint(100, 999)}"
        telefono = f"7{random.randint(1000000, 9999999)}"
        matricula = f"MAT-N{ci_counter}"
        zona_id = random.choice(zona_ids)
        medicos_persona.append((ci, nombre, str(fecha_nac), sexo, direccion, telefono, matricula, zona_id))
        medicos_esp.append(esp_id)

# Insertar personas (medicos)
psycopg2.extras.execute_batch(cursor, """
    INSERT INTO persona (ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
""", medicos_persona, page_size=1000)
conn.commit()

# Obtener IDs asignados (los ultimos N)
cursor.execute("SELECT id_persona FROM persona ORDER BY id_persona DESC LIMIT %s", (len(medicos_persona),))
new_med_ids = sorted([row[0] for row in cursor.fetchall()])

# Crear registros en personal (con especialidad, cargo=1 Medico, turno, disponibilidad)
personal_data = []
for i, id_persona in enumerate(new_med_ids):
    personal_data.append((id_persona, medicos_esp[i], 1, random.choice([1, 2, 3]), random.choice([1, 2])))

psycopg2.extras.execute_batch(cursor, """
    INSERT INTO personal (id_persona, id_especialidad, id_cargo, id_turno, id_estado_disponibilidad)
    VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING
""", personal_data, page_size=1000)
conn.commit()
print(f"  Medicos nuevos: {len(medicos_persona)} (persona + personal)")

# ==============================================================
# 4. AGREGAR NUEVOS PACIENTES (persona + paciente)
# ==============================================================
print("\n[4/10] Agregando pacientes nuevos (30,000)...")

pacientes_persona = []
ci_counter = 3000001

for _ in range(30000):
    sexo = random.choice(['M', 'F'])
    nombre = random.choice(nombres_m if sexo == 'M' else nombres_f) + " " + \
             random.choice(apellidos) + " " + random.choice(apellidos)
    ci = str(ci_counter); ci_counter += 1
    fecha_nac = fake.date_between(start_date='-85y', end_date='-1y')
    direccion = f"Calle {fake.street_name()} #{random.randint(100, 999)}"
    telefono = f"7{random.randint(1000000, 9999999)}"
    zona_id = random.choice(zona_ids)
    pacientes_persona.append((ci, nombre, str(fecha_nac), sexo, direccion, telefono, None, zona_id))

for i in range(0, len(pacientes_persona), 5000):
    batch = pacientes_persona[i:i + 5000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO persona (ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Lote {i // 5000 + 1}: {len(batch)} pacientes")

# Registrar en tabla paciente
cursor.execute("""
    SELECT id_persona FROM persona
    WHERE (matricula IS NULL OR matricula = '')
    AND id_persona NOT IN (SELECT id_persona FROM paciente)
""")
pacs_sin_registrar = [row[0] for row in cursor.fetchall()]
if pacs_sin_registrar:
    psycopg2.extras.execute_batch(cursor,
        "INSERT INTO paciente (id_persona) VALUES (%s) ON CONFLICT DO NOTHING",
        [(pid,) for pid in pacs_sin_registrar], page_size=1000)
    conn.commit()
print(f"  Total pacientes nuevos: {len(pacientes_persona)}")

# ==============================================================
# 5. AGREGAR HORARIOS MEDICOS
# ==============================================================
print("\n[5/10] Agregando horarios medicos...")

cursor.execute("""
    SELECT p.id_persona FROM persona p
    WHERE p.matricula IS NOT NULL
    AND p.id_persona NOT IN (SELECT id_persona FROM horario_medico)
""")
medicos_sin_horario = [row[0] for row in cursor.fetchall()]

horarios_data = []
for med_id in medicos_sin_horario:
    dias = random.sample(range(1, 7), random.randint(3, 5))
    for dia in dias:
        hora_inicio = random.choice(["07:00", "08:00", "09:00", "14:00", "15:00", "20:00"])
        hora_fin_map = {"07:00": "13:00", "08:00": "14:00", "09:00": "15:00",
                        "14:00": "20:00", "15:00": "21:00", "20:00": "02:00"}
        horarios_data.append((dia, hora_inicio, hora_fin_map[hora_inicio], random.randint(8, 20), med_id))

if horarios_data:
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO horario_medico (dia_semana, hora_inicio, hora_fin, cupo_maximo, id_persona)
        VALUES (%s, %s, %s, %s, %s)
    """, horarios_data, page_size=1000)
    conn.commit()
    print(f"  Horarios nuevos: {len(horarios_data)}")

# ==============================================================
# 6. GENERAR CITAS MEDICAS (50,000)
# ==============================================================
print("\n[6/10] Generando citas medicas nuevas (50,000)...")

cursor.execute("SELECT id_persona FROM persona WHERE matricula IS NULL OR matricula = ''")
todos_pacientes = [row[0] for row in cursor.fetchall()]

cursor.execute("""
    SELECT pe.id_persona, pr.id_especialidad
    FROM persona pe JOIN personal pr ON pe.id_persona = pr.id_persona
""")
todos_medicos = cursor.fetchall()

esp_medicos = {}
for med_id, esp_id in todos_medicos:
    esp_medicos.setdefault(esp_id, []).append(med_id)

cursor.execute("SELECT id_especialidad, nombre FROM especialidad")
esp_id_nombre = {row[0]: row[1] for row in cursor.fetchall()}

estados = ["Atendida", "Atendida", "Atendida", "Agendada", "Cancelada", "No asistio"]
horas = ["07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30",
         "11:00", "11:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
         "17:00", "19:00", "19:30", "20:00"]

citas_data = []
for _ in range(50000):
    paciente_id = random.choice(todos_pacientes)
    esp_id = random.choice(especialidad_ids)
    medicos_en_esp = esp_medicos.get(esp_id, [])
    medico_id = random.choice(medicos_en_esp) if medicos_en_esp else random.choice([m[0] for m in todos_medicos])
    fecha_cita = fake.date_between(start_date='-2y', end_date='today')
    fecha_registro = fake.date_between(start_date=fecha_cita - timedelta(days=30), end_date=fecha_cita)
    citas_data.append((str(fecha_registro), str(fecha_cita), random.choice(horas),
                       random.randint(1, 30), random.choice(estados), paciente_id, medico_id))

for i in range(0, len(citas_data), 10000):
    batch = citas_data[i:i + 10000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO cita_medica (fecha_registro, fecha_cita, hora, numero_turno, estado, id_paciente, id_medico)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Lote {i // 10000 + 1}: {len(batch)} citas")
print(f"  Total citas nuevas: {len(citas_data)}")

# ==============================================================
# 7. GENERAR DIAGNOSTICOS
# ==============================================================
print("\n[7/10] Generando diagnosticos...")

cursor.execute("""
    SELECT cm.id_cita, pr.id_especialidad
    FROM cita_medica cm
    JOIN personal pr ON cm.id_medico = pr.id_persona
    WHERE cm.estado = 'Atendida'
    AND cm.id_cita NOT IN (SELECT id_cita FROM diagnostico)
""")
citas_sin_diagnostico = cursor.fetchall()

cursor.execute("SELECT id_tipo_diagnostico FROM tipo_diagnostico")
tipo_diag_ids = [row[0] for row in cursor.fetchall()]

observaciones_posibles = [
    "Paciente refiere dolor agudo, se solicitan estudios complementarios",
    "Se observan signos de infeccion, se inicia tratamiento antibiotico",
    "Resultados de laboratorio dentro de parametros normales",
    "Se detecta anomalia en estudios de imagen, se deriva a especialista",
    "Cuadro clinico estable, se mantiene medicacion actual",
    "Paciente presenta sintomas leves, se recomienda seguimiento",
    "Evaluacion inicial, se solicitan examenes de rutina",
    "Se ajusta dosis de medicacion por efectos secundarios",
    "Control post-operatorio satisfactorio",
    "Paciente con evolucion favorable, se programa alta",
]

procedimientos_texto = [
    "Consulta ambulatoria", "Examenes de laboratorio", "Radiografia", "Ecografia",
    "Cirugia menor", "Terapia fisica", "Endoscopia", "Biopsia",
    "Electrocardiograma", "Resonancia magnetica", "Tomografia computarizada"]

diag_data = []
for cita_id, esp_id in citas_sin_diagnostico:
    esp_nombre = esp_id_nombre.get(esp_id, "Medicina General")
    enfermedades = enfermedades_por_especialidad.get(esp_nombre,
                   enfermedades_por_especialidad["Medicina General"])
    diag_data.append((random.choice(enfermedades), random.choice(observaciones_posibles),
                      random.choice(procedimientos_texto), cita_id, random.choice(tipo_diag_ids)))

for i in range(0, len(diag_data), 10000):
    batch = diag_data[i:i + 10000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO diagnostico (descripcion, observaciones, tipo_procedimiento, id_cita, id_tipo_diagnostico)
        VALUES (%s, %s, %s, %s, %s)
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Lote {i // 10000 + 1}: {len(batch)} diagnosticos")
print(f"  Total diagnosticos: {len(diag_data)}")

# ==============================================================
# 8. GENERAR RECETAS
# ==============================================================
print("\n[8/10] Generando recetas...")

cursor.execute("""
    SELECT id_diagnostico FROM diagnostico
    WHERE id_diagnostico NOT IN (SELECT id_diagnostico FROM receta)
""")
diags_sin_receta = [row[0] for row in cursor.fetchall()]

medicamentos_lista = [
    "Paracetamol 500mg", "Ibuprofeno 400mg", "Amoxicilina 500mg", "Omeprazol 20mg",
    "Aspirina 100mg", "Loratadina 10mg", "Metformina 850mg", "Atorvastatina 20mg",
    "Losartan 50mg", "Prednisona 5mg", "Diclofenaco 50mg", "Cefalexina 500mg",
    "Azitromicina 500mg", "Ciprofloxacino 500mg", "Ranitidina 150mg", "Clonazepam 0.5mg",
    "Enalapril 10mg", "Amlodipino 5mg", "Salbutamol inhalador", "Insulina NPH"]

indicaciones_lista = [
    "Tomar con alimentos cada 8 horas", "Tomar en ayunas cada 12 horas",
    "Tomar antes de dormir", "Aplicar cada 24 horas", "Tomar cada 6 horas por 7 dias",
    "Tomar una vez al dia por la manana", "No mezclar con alcohol, tomar cada 8 horas",
    "Tomar despues de cada comida", "Aplicar segun indicacion medica",
    "Uso continuo, no suspender sin consulta"]

receta_data = []
for diag_id in diags_sin_receta:
    meds = random.sample(medicamentos_lista, random.randint(1, 3))
    receta_data.append((", ".join(meds), random.choice(indicaciones_lista), diag_id))

for i in range(0, len(receta_data), 10000):
    batch = receta_data[i:i + 10000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO receta (medicamentos, indicaciones, id_diagnostico)
        VALUES (%s, %s, %s)
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Lote {i // 10000 + 1}: {len(batch)} recetas")
print(f"  Total recetas: {len(receta_data)}")

# ==============================================================
# 9. GENERAR PAGOS
# ==============================================================
print("\n[9/10] Generando pagos...")

cursor.execute("""
    SELECT id_cita FROM cita_medica
    WHERE id_cita NOT IN (SELECT id_cita FROM pago) AND estado = 'Atendida'
""")
citas_sin_pago = [row[0] for row in cursor.fetchall()]

pago_data = []
for cita_id in citas_sin_pago:
    pago_data.append((cita_id, round(random.uniform(50, 2000), 2), random.choice([1, 2, 3, 4]),
                      str(fake.date_between(start_date='-2y', end_date='today')), random.choice([1, 2, 2, 2])))

for i in range(0, len(pago_data), 10000):
    batch = pago_data[i:i + 10000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO pago (id_cita, monto_total, id_metodo_pago, fecha_pago, id_estado_pago)
        VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Pagos lote {i // 10000 + 1}: {len(batch)}")

# ==============================================================
# 10. GENERAR HISTORIAL CLINICO
# ==============================================================
print("\n[10/10] Generando historial clinico...")

cursor.execute("""
    SELECT id_paciente FROM paciente
    WHERE id_paciente NOT IN (SELECT id_paciente FROM historial_clinico)
""")
pacs_sin_hist = [row[0] for row in cursor.fetchall()]

hist_data = []
for pac_id in pacs_sin_hist:
    hist_data.append((pac_id, str(fake.date_between(start_date='-3y', end_date='today')),
                      random.choice([1, 2, 3, 4]),
                      random.choice(["Paciente ingresa por primera vez",
                                     "Registro de control periodico",
                                     "Actualizacion de historial",
                                     "Seguimiento post-tratamiento",
                                     "Paciente derivado"])))

for i in range(0, len(hist_data), 10000):
    batch = hist_data[i:i + 10000]
    psycopg2.extras.execute_batch(cursor, """
        INSERT INTO historial_clinico (id_paciente, fecha_registro, id_tipo_registro, observaciones)
        VALUES (%s, %s, %s, %s)
    """, batch, page_size=1000)
    conn.commit()
    print(f"  Historial lote {i // 10000 + 1}: {len(batch)}")

# ==============================================================
# RESUMEN FINAL
# ==============================================================
print("\n" + "=" * 60)
print("RESUMEN FINAL")
print("=" * 60)

tables = [
    'zona', 'especialidad', 'tipo_diagnostico', 'persona', 'paciente', 'personal',
    'horario_medico', 'cita_medica', 'diagnostico', 'receta',
    'procedimiento_medico', 'medicamento', 'pago', 'diagnostico_procedimiento',
    'historial_clinico', 'receta_detalle',
    'cat_genero', 'cat_cargo', 'cat_turno', 'cat_estado_disponibilidad',
    'cat_gravedad', 'cat_estado_cita', 'cat_metodo_pago', 'cat_estado_pago', 'cat_tipo_registro'
]

total = 0
for t in tables:
    cursor.execute(f"SELECT COUNT(*) FROM {t}")
    count = cursor.fetchone()[0]
    total += count
    if count > 0:
        print(f"  {t}: {count:,}")
print(f"\n  TOTAL: {total:,}")

cursor.execute("SELECT nombre FROM especialidad ORDER BY nombre")
print("\n  ESPECIALIDADES:")
for row in cursor.fetchall():
    print(f"    - {row[0]}")

conn.close()
print("\nDatos insertados correctamente en PostgreSQL!")
