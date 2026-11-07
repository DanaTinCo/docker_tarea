DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS reporte_incidencia_producto CASCADE;
DROP TABLE IF EXISTS tematica_comercial CASCADE;
DROP TABLE IF EXISTS alerta_vencimiento CASCADE;
DROP TABLE IF EXISTS transferencia_producto CASCADE;
DROP TABLE IF EXISTS conteo_inventario_abc CASCADE;
DROP TABLE IF EXISTS cierre_caja_diario CASCADE;
DROP TABLE IF EXISTS venta CASCADE;
DROP TABLE IF EXISTS solicitud_ausencia CASCADE;
DROP TABLE IF EXISTS asistencia CASCADE;
DROP TABLE IF EXISTS tarea CASCADE;
DROP TABLE IF EXISTS evaluacion_desempeno CASCADE;
DROP TABLE IF EXISTS meta_venta CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;
DROP TABLE IF EXISTS sucursal CASCADE;

DROP TYPE IF EXISTS rol_enum CASCADE;
DROP TYPE IF EXISTS estado_solicitud_enum CASCADE;
DROP TYPE IF EXISTS estado_tarea_enum CASCADE;
DROP TYPE IF EXISTS estado_conteo_enum CASCADE;
DROP TYPE IF EXISTS estado_transferencia_enum CASCADE;
DROP TYPE IF EXISTS estado_venta_enum CASCADE;

CREATE TYPE rol_enum AS ENUM ('ADMINISTRADOR', 'SUPERVISORA', 'ASESORA');
CREATE TYPE estado_solicitud_enum AS ENUM ('PENDIENTE', 'APROBADA', 'RECHAZADA');
CREATE TYPE estado_tarea_enum AS ENUM ('PENDIENTE', 'COMPLETADA');
CREATE TYPE estado_conteo_enum AS ENUM ('NO_CONTABILIZADO', 'EN_PROCESO', 'FINALIZADO');
CREATE TYPE estado_transferencia_enum AS ENUM ('SOLICITADA', 'EN_TRANSITO', 'RECIBIDA', 'CANCELADA', 'RECHAZADA');
CREATE TYPE estado_venta_enum AS ENUM ('COMPLETADA', 'ANULADA');

CREATE TABLE sucursal (
    id_sucursal SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    activa BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT,
    updated_by INT
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_sucursal INT REFERENCES sucursal(id_sucursal) ON DELETE SET NULL,
    rol rol_enum NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    ci VARCHAR(20) UNIQUE NOT NULL,
    complemento_ci VARCHAR(10),
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255), 
    pin_acceso VARCHAR(10),
    google_id VARCHAR(255) UNIQUE, 
    avatar_url TEXT,
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMPTZ,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

ALTER TABLE sucursal ADD CONSTRAINT fk_sucursal_created_by FOREIGN KEY (created_by) REFERENCES usuario(id_usuario);
ALTER TABLE sucursal ADD CONSTRAINT fk_sucursal_updated_by FOREIGN KEY (updated_by) REFERENCES usuario(id_usuario);

CREATE TABLE meta_venta (
    id_meta SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    periodo_mes DATE NOT NULL,
    monto_meta NUMERIC(12, 2) NOT NULL CHECK (monto_meta > 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE tematica_comercial (
    id_tematica SERIAL PRIMARY KEY,
    id_sucursal INT REFERENCES sucursal(id_sucursal) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    producto_foco VARCHAR(150),
    meta_unidades INT DEFAULT 0,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin DATE,
    activa BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE evaluacion_desempeno (
    id_evaluacion SERIAL PRIMARY KEY,
    id_asesora INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_supervisora INT NOT NULL REFERENCES usuario(id_usuario),
    periodo_mes DATE NOT NULL,
    nota_limpieza INT NOT NULL CHECK (nota_limpieza BETWEEN 1 AND 5),
    nota_puntualidad INT NOT NULL CHECK (nota_puntualidad BETWEEN 1 AND 5),
    nota_atencion INT NOT NULL CHECK (nota_atencion BETWEEN 1 AND 5),
    nota_frecuencia_venta INT NOT NULL CHECK (nota_frecuencia_venta BETWEEN 1 AND 5),
    calificacion_difusa_final NUMERIC(5, 2),
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE tarea (
    id_tarea BIGSERIAL PRIMARY KEY,
    id_asignador INT NOT NULL REFERENCES usuario(id_usuario),
    id_asignado INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    estado estado_tarea_enum DEFAULT 'PENDIENTE' NOT NULL,
    fecha_limite TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE asistencia (
    id_asistencia BIGSERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    fecha DATE NOT NULL,
    hora_entrada TIMESTAMPTZ NOT NULL,
    hora_salida TIMESTAMPTZ,
    minutos_retraso INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE solicitud_ausencia (
    id_solicitud SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    motivo TEXT NOT NULL,
    comprobante_url TEXT,
    estado estado_solicitud_enum DEFAULT 'PENDIENTE' NOT NULL,
    id_revisor_admin INT REFERENCES usuario(id_usuario),
    comentario_revisor TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario),
    CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE venta (
    id_venta BIGSERIAL PRIMARY KEY,
    id_asesora INT NOT NULL REFERENCES usuario(id_usuario),
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    numero_factura VARCHAR(50) NOT NULL,
    monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
    cantidad_productos INT DEFAULT 1 NOT NULL CHECK (cantidad_productos > 0),
    estado estado_venta_enum DEFAULT 'COMPLETADA' NOT NULL,
    fecha_transaccion DATE NOT NULL,
    hora_transaccion TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE cierre_caja_diario (
    id_cierre SERIAL PRIMARY KEY,
    id_supervisora INT NOT NULL REFERENCES usuario(id_usuario),
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    fecha DATE NOT NULL,
    monto_efectivo_declarado NUMERIC(12, 2) NOT NULL,
    monto_otros_medios NUMERIC(12, 2) NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE conteo_inventario_abc (
    id_conteo SERIAL PRIMARY KEY,
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    id_supervisora INT NOT NULL REFERENCES usuario(id_usuario),
    periodo_mes DATE NOT NULL,
    letra_alfabeto CHAR(1) NOT NULL CHECK (letra_alfabeto ~ '^[A-Z]$'),
    estado estado_conteo_enum DEFAULT 'NO_CONTABILIZADO' NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE transferencia_producto (
    id_transferencia BIGSERIAL PRIMARY KEY,
    id_sucursal_origen INT NOT NULL REFERENCES sucursal(id_sucursal),
    id_sucursal_destino INT NOT NULL REFERENCES sucursal(id_sucursal),
    id_solicitante INT NOT NULL REFERENCES usuario(id_usuario),
    descripcion_producto VARCHAR(150) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    estado estado_transferencia_enum DEFAULT 'SOLICITADA' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario),
    CHECK (id_sucursal_origen <> id_sucursal_destino)
);

CREATE TABLE alerta_vencimiento (
    id_alerta SERIAL PRIMARY KEY,
    id_asesora INT NOT NULL REFERENCES usuario(id_usuario),
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    descripcion_producto VARCHAR(150) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha_vencimiento DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'VIGENTE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by INT REFERENCES usuario(id_usuario),
    updated_by INT REFERENCES usuario(id_usuario)
);

CREATE TABLE reporte_incidencia_producto (
    id_reporte BIGSERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario),
    id_sucursal INT NOT NULL REFERENCES sucursal(id_sucursal),
    tipo_incidencia VARCHAR(50) NOT NULL DEFAULT 'STOCK_BAJO',
    descripcion_producto VARCHAR(150) NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    observaciones TEXT,
    estado VARCHAR(30) DEFAULT 'PENDIENTE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX uq_meta_venta ON meta_venta (id_usuario, periodo_mes) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_evaluacion ON evaluacion_desempeno (id_asesora, periodo_mes) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_asistencia_diaria ON asistencia (id_usuario, fecha) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_factura_sucursal ON venta (numero_factura, id_sucursal) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_cierre_sucursal_fecha ON cierre_caja_diario (id_sucursal, fecha) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_conteo_abc ON conteo_inventario_abc (id_sucursal, periodo_mes, letra_alfabeto) WHERE deleted_at IS NULL;

CREATE INDEX idx_venta_analytics ON venta (fecha_transaccion, id_asesora, monto);
CREATE INDEX idx_venta_sucursal_fecha ON venta (id_sucursal, fecha_transaccion) WHERE estado = 'COMPLETADA';
CREATE INDEX idx_asistencia_busqueda ON asistencia (id_usuario, fecha);
CREATE INDEX idx_tarea_seguimiento ON tarea (id_asignado, estado) WHERE deleted_at IS NULL;
CREATE INDEX idx_conteo_pendientes ON conteo_inventario_abc (id_sucursal, estado) WHERE estado != 'FINALIZADO';
CREATE INDEX idx_transferencias_estado ON transferencia_producto (estado, id_sucursal_destino);
CREATE INDEX idx_usuario_listado ON usuario (deleted_at, rol, activo, nombre_completo);
CREATE INDEX idx_usuario_sucursal ON usuario (id_sucursal, deleted_at);

CREATE TABLE audit_log (
    id_audit BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'SOFT_DEL')),
    old_data JSONB,
    new_data JSONB,
    changed_by INT,
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_log_lookup ON audit_log (table_name, record_id);

CREATE OR REPLACE FUNCTION fn_audit_trigger() RETURNS TRIGGER AS $$
DECLARE
    v_record_id BIGINT;
    v_user_id INT;
    v_pk_name TEXT := TG_ARGV[0];
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        v_user_id := NEW.updated_by;
        v_record_id := (to_jsonb(NEW)->>v_pk_name)::BIGINT;
        
        IF (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL) THEN
            INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
            VALUES (TG_TABLE_NAME, v_record_id, 'SOFT_DEL', to_jsonb(OLD), to_jsonb(NEW), v_user_id);
        ELSE
            INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
            VALUES (TG_TABLE_NAME, v_record_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), v_user_id);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        v_user_id := NEW.created_by;
        v_record_id := (to_jsonb(NEW)->>v_pk_name)::BIGINT;
        
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, v_record_id, 'INSERT', NULL, to_jsonb(NEW), v_user_id);
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_solicitud_ausencia
AFTER INSERT OR UPDATE ON solicitud_ausencia
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger('id_solicitud');

CREATE TRIGGER trg_audit_transferencia_producto
AFTER INSERT OR UPDATE ON transferencia_producto
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger('id_transferencia');

CREATE TRIGGER trg_audit_cierre_caja
AFTER INSERT OR UPDATE ON cierre_caja_diario
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger('id_cierre');

CREATE TRIGGER trg_audit_evaluacion_desempeno
AFTER INSERT OR UPDATE ON evaluacion_desempeno
FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger('id_evaluacion');