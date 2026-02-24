-- Active: 1769781403695@@127.0.0.1@5432@hospitaldb
-- Carga de catálogos y datos maestros base

BEGIN;

INSERT INTO cat_genero (nombre) VALUES
('Masculino'), ('Femenino'), ('No binario')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_especialidad (nombre, piso) VALUES
('Medicina General', 'Piso 1'),
('Pediatría', 'Piso 2'),
('Ginecología', 'Piso 3'),
('Cardiología', 'Piso 4'),
('Traumatología', 'Piso 2'),
('Neurología', 'Piso 5'),
('Dermatología', 'Piso 3'),
('Odontología', 'Piso 1')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_cargo (nombre) VALUES
('Médico'), ('Enfermería'), ('Recepción'), ('Laboratorio'), ('Farmacia'), ('Administración')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_turno (nombre) VALUES
('Mañana'), ('Tarde'), ('Noche')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_estado_disponibilidad (nombre) VALUES
('Disponible'), ('Ocupado'), ('Ausente'), ('Vacaciones')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_gravedad (nombre) VALUES
('Leve'), ('Moderada'), ('Severa'), ('Crítica')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_estado_cita (nombre) VALUES
('Agendada'), ('Atendida'), ('Cancelada'), ('No asistió')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_metodo_pago (nombre) VALUES
('Efectivo'), ('Tarjeta'), ('Transferencia'), ('Seguro')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_estado_pago (nombre) VALUES
('Pendiente'), ('Pagado'), ('Rechazado'), ('Anulado')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cat_tipo_registro (nombre) VALUES
('Ingreso'), ('Alta'), ('Observación'), ('Evolución')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO procedimiento_medico (nombre, costo_base, tiempo_estimado_min) VALUES
('Radiografía', 120.00, 20),
('Electrocardiograma', 150.00, 25),
('Ecografía', 200.00, 30),
('Sutura menor', 80.00, 15),
('Curación avanzada', 60.00, 20),
('Tomografía', 550.00, 45),
('Resonancia', 900.00, 60),
('Laboratorio completo', 180.00, 35)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO medicamento (nombre_medicamento, stock_actual, costo_unitario) VALUES
('Paracetamol 500mg', 3000, 1.20),
('Ibuprofeno 400mg', 2500, 1.50),
('Amoxicilina 500mg', 1800, 2.80),
('Omeprazol 20mg', 2200, 1.90),
('Loratadina 10mg', 1500, 1.10),
('Metformina 850mg', 1200, 2.40),
('Losartán 50mg', 1300, 2.20),
('Atorvastatina 20mg', 900, 3.00),
('Salbutamol inhalador', 500, 8.50),
('Diclofenaco 50mg', 1400, 1.70),
('Azitromicina 500mg', 700, 4.20),
('Cefalexina 500mg', 900, 3.10)
ON CONFLICT (nombre_medicamento) DO NOTHING;

COMMIT;
