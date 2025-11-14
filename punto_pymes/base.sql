-- Corrected schema (ASCII identifiers):
-- This file is for reference; execute the SQL in Supabase SQL editor as needed.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.empresas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  ruc varchar(32) UNIQUE,
  direccion text,
  telefono varchar(32),
  email text,
  logo_url text,
  hora_entrada time,
  hora_salida time,
  hora_almuerzo time,
  hora_entrada_almuerzo time,
  tolerancia_minutos integer DEFAULT 0,
  estado text DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','pendiente')),
  creado_en timestamptz DEFAULT now(),
  actualizado_en timestamptz DEFAULT now(),
  codigo_empresa text UNIQUE
);

CREATE TABLE IF NOT EXISTS public.usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  nombre_completo text NOT NULL,
  email text NOT NULL UNIQUE,
  contrasena_hash text,
  rol text NOT NULL CHECK (rol IN ('superadmin','admin','empleado')),
  telefono varchar(32),
  avatar_url text,
  estado boolean DEFAULT true,
  creado_en timestamptz DEFAULT now(),
  ultimo_login timestamptz,
  actualizado_en timestamptz DEFAULT now()
);

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

  -- Indexes
  CREATE INDEX IF NOT EXISTS idx_empresas_nombre ON public.empresas (lower(nombre));
  CREATE INDEX IF NOT EXISTS idx_usuarios_empresa ON public.usuarios (empresa_id);
  CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON public.usuarios (rol);
  CREATE INDEX IF NOT EXISTS idx_asistencia_usuario_fecha ON public.registros_asistencia (usuario_id, registrado_en DESC);
  CREATE INDEX IF NOT EXISTS idx_asistencia_empresa_fecha ON public.registros_asistencia (empresa_id, registrado_en DESC);
  CREATE INDEX IF NOT EXISTS idx_solicitudes_empresa_estado ON public.solicitudes_registro (empresa_id, estado);
  CREATE INDEX IF NOT EXISTS idx_anuncios_empresa ON public.anuncios (empresa_id);
  CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON public.notificaciones (usuario_id);
  CREATE INDEX IF NOT EXISTS idx_media_empresa ON public.media (empresa_id);

  -- Trigger helper
  CREATE OR REPLACE FUNCTION public.actualizar_actualizado_en()
  RETURNS TRIGGER AS $fn$
  BEGIN
    NEW.actualizado_en := now();
    RETURN NEW;
  END;
  $fn$ LANGUAGE plpgsql;

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