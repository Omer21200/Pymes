-- Habilitar extensión para gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================================
-- TABLAS PRINCIPALES
-- ==========================================================

-- Tabla: empresas
CREATE TABLE IF NOT EXISTS public.empresas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  ruc varchar(32) UNIQUE,
  direccion text,
  telefono varchar(32),
  email text,
  logo_url text,
  codigo_empresa text UNIQUE,
  hora_entrada time,
  hora_salida time,
  hora_almuerzo time,
  hora_entrada_almuerzo time,
  tolerancia_minutos integer DEFAULT 0,
  estado text DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','pendiente')),
  creado_en timestamptz DEFAULT now(),
  actualizado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_empresas_nombre ON public.empresas (lower(nombre));

-- Tabla: usuarios
CREATE TABLE IF NOT EXISTS public.usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  nombre_completo text NOT NULL,
  email text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  rol text NOT NULL CHECK (rol IN ('superadmin','admin','empleado')),
  telefono varchar(32),
  avatar_url text,
  estado boolean DEFAULT true,
  creado_en timestamptz DEFAULT now(),
  ultimo_login timestamptz,
  actualizado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_empresa ON public.usuarios (empresa_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON public.usuarios (rol);

-- Tabla: registros_asistencia
CREATE TABLE IF NOT EXISTS public.registros_asistencia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  tipo text NOT NULL CHECK (tipo IN ('entrada','salida')),
  registrado_en timestamptz NOT NULL DEFAULT now(),
  capturado_en timestamptz,
  estado text CHECK (estado IN ('puntual','tarde','ausente')),
  latitud numeric(10,6),
  longitud numeric(10,6),
  foto_url text,
  dispositivo jsonb,
  notas text,
  creado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_asistencia_usuario_fecha ON public.registros_asistencia (usuario_id, registrado_en DESC);
CREATE INDEX IF NOT EXISTS idx_asistencia_empresa_fecha ON public.registros_asistencia (empresa_id, registrado_en DESC);

-- Tabla: solicitudes_registro
CREATE TABLE IF NOT EXISTS public.solicitudes_registro (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  nombre_completo text NOT NULL,
  email text,
  telefono varchar(32),
  ci varchar(64),
  cargo text,
  solicitado_en timestamptz DEFAULT now(),
  estado text DEFAULT 'pendiente' CHECK (estado IN ('pendiente','aprobado','rechazado')),
  revisado_por uuid REFERENCES public.usuarios(id),
  revisado_en timestamptz,
  notas_revision text
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_empresa_estado ON public.solicitudes_registro (empresa_id, estado);

-- Tabla: anuncios
CREATE TABLE IF NOT EXISTS public.anuncios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  mensaje text NOT NULL,
  creado_por uuid REFERENCES public.usuarios(id),
  programado_en timestamptz,
  enviado boolean DEFAULT false,
  enviado_en timestamptz,
  metadatos jsonb,
  creado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anuncios_empresa ON public.anuncios (empresa_id);

-- Tabla: notificaciones
CREATE TABLE IF NOT EXISTS public.notificaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid REFERENCES public.usuarios(id),
  titulo text,
  contenido text,
  tipo text,
  payload jsonb,
  leido boolean DEFAULT false,
  creado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON public.notificaciones (usuario_id);

-- Tabla: media
CREATE TABLE IF NOT EXISTS public.media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  bucket text,
  ruta text NOT NULL,
  url text NOT NULL,
  metadatos jsonb,
  subido_por uuid REFERENCES public.usuarios(id),
  creado_en timestamptz DEFAULT now(),
  actualizado_en timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_media_empresa ON public.media (empresa_id);

-- ==========================================================
-- FUNCIONES Y TRIGGERS
-- ==========================================================

CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en()
RETURNS TRIGGER AS $fn$
BEGIN
  NEW.actualizado_en := now();
  RETURN NEW;
END;
$fn$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS trg_actualizar_media ON public.media;
CREATE TRIGGER trg_actualizar_media
BEFORE UPDATE ON public.media
FOR EACH ROW
EXECUTE FUNCTION public.actualizar_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizar_empresas ON public.empresas;
CREATE TRIGGER trg_actualizar_empresas
BEFORE UPDATE ON public.empresas
FOR EACH ROW
EXECUTE FUNCTION public.actualizar_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizar_usuarios ON public.usuarios;
CREATE TRIGGER trg_actualizar_usuarios
BEFORE UPDATE ON public.usuarios
FOR EACH ROW
EXECUTE FUNCTION public.actualizar_actualizado_en();

-- Helper function: genera un codigo unico para empresas
CREATE OR REPLACE FUNCTION public.generar_codigo_unico(base_in text, email_in text DEFAULT NULL)
RETURNS text AS $fn$
DECLARE
  base_nombre text := regexp_replace(lower(coalesce(base_in, '')), '[^a-z0-9]', '', 'g');
  codigo_final text;
  intento int := 0;
BEGIN
  IF base_nombre = '' THEN
    base_nombre := regexp_replace(lower(coalesce(email_in, '')), '[^a-z0-9]', '', 'g');
  END IF;

  IF base_nombre = '' THEN
    base_nombre := left(replace(gen_random_uuid()::text, '-', ''), 8);
  END IF;

  -- Serializa por prefijo para reducir race conditions cuando se generan
  -- códigos concurrentemente para el mismo base_nombre.
  PERFORM pg_advisory_xact_lock(hashtext(base_nombre), 0);

  LOOP
    intento := intento + 1;
    codigo_final := base_nombre || '-' || lpad((floor(random() * 10000))::int::text, 4, '0');

    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.empresas WHERE codigo_empresa = codigo_final
    );

    IF intento > 100 THEN
      RAISE EXCEPTION 'No se pudo generar un codigo_empresa unico para % despues de % intentos', base_nombre, intento;
    END IF;
  END LOOP;

  RETURN codigo_final;
END;
$fn$ LANGUAGE plpgsql;

-- Trigger wrapper que usa la función helper
CREATE OR REPLACE FUNCTION public.generar_codigo_empresa()
RETURNS trigger AS $fn$
BEGIN
  IF NEW.codigo_empresa IS NULL THEN
    NEW.codigo_empresa := public.generar_codigo_unico(NEW.nombre, NEW.email);
  END IF;
  RETURN NEW;
END;
$fn$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generar_codigo_empresa ON public.empresas;
CREATE TRIGGER trg_generar_codigo_empresa
BEFORE INSERT ON public.empresas
FOR EACH ROW
WHEN (NEW.codigo_empresa IS NULL)
EXECUTE FUNCTION public.generar_codigo_empresa();

-- BACKFILL: Descomenta y ejecuta si quieres rellenar codigo_empresa para filas existentes
-- UPDATE public.empresas
-- SET codigo_empresa = public.generar_codigo_unico(nombre, email)
-- WHERE codigo_empresa IS NULL;