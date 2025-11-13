-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.anuncios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  empresa_id uuid,
  titulo text NOT NULL,
  mensaje text NOT NULL,
  creado_por uuid,
  programado_en timestamp with time zone,
  enviado boolean DEFAULT false,
  enviado_en timestamp with time zone,
  metadatos jsonb,
  creado_en timestamp with time zone DEFAULT now(),
  CONSTRAINT anuncios_pkey PRIMARY KEY (id),
  CONSTRAINT anuncios_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id),
  CONSTRAINT anuncios_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas(id)
);
CREATE TABLE public.empresas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  ruc character varying UNIQUE,
  direccion text,
  telefono character varying,
  email text,
  logo_url text,
  hora_entrada time without time zone,
  hora_salida time without time zone,
  hora_almuerzo time without time zone,
  hota_entrada_almuerzo time without time zone,
  tolerancia_minutos integer DEFAULT 0,
  estado text DEFAULT 'activo'::text CHECK (estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'pendiente'::text])),
  creado_en timestamp with time zone DEFAULT now(),
  actualizado_en timestamp with time zone DEFAULT now(),
  codigo_empresa text NOT NULL UNIQUE,
  CONSTRAINT empresas_pkey PRIMARY KEY (id)
);
CREATE TABLE public.media (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  empresa_id uuid,
  bucket text,
  ruta text NOT NULL,
  url text NOT NULL,
  metadatos jsonb,
  subido_por uuid,
  creado_en timestamp with time zone DEFAULT now(),
  actualizado_en timestamp with time zone DEFAULT now(),
  CONSTRAINT media_pkey PRIMARY KEY (id),
  CONSTRAINT media_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),
  CONSTRAINT media_subido_por_fkey FOREIGN KEY (subido_por) REFERENCES public.usuarios(id)
);
CREATE TABLE public.notificaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  titulo text,
  contenido text,
  tipo text,
  payload jsonb,
  leido boolean DEFAULT false,
  creado_en timestamp with time zone DEFAULT now(),
  CONSTRAINT notificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.registros_asistencia (
  id_registro uuid NOT NULL DEFAULT gen_random_uuid(),
  id uuid,
  empresa_id uuid,
  tipo text NOT NULL CHECK (tipo = ANY (ARRAY['entrada'::text, 'salida'::text])),
  registrado_en timestamp with time zone NOT NULL DEFAULT now(),
  capturado_en timestamp with time zone,
  estado text CHECK (estado = ANY (ARRAY['puntual'::text, 'tarde'::text, 'ausente'::text])),
  latitud numeric,
  longitud numeric,
  foto_url text,
  dispositivo jsonb,
  notas text,
  creado_en timestamp with time zone DEFAULT now(),
  CONSTRAINT registros_asistencia_pkey PRIMARY KEY (id_registro),
  CONSTRAINT registros_asistencia_id_fkey FOREIGN KEY (id) REFERENCES public.usuarios(id),
  CONSTRAINT registros_asistencia_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas(id)
);
CREATE TABLE public.solicitudes_registro (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  empresa_id uuid,
  nombre_completo text NOT NULL,
  email text,
  telefono character varying,
  ci character varying,
  cargo text,
  solicitado_en timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'pendiente'::text CHECK (estado = ANY (ARRAY['pendiente'::text, 'aprobado'::text, 'rechazado'::text])),
  revisado_por uuid,
  revisado_en timestamp with time zone,
  notas_revision text,
  CONSTRAINT solicitudes_registro_pkey PRIMARY KEY (id),
  CONSTRAINT solicitudes_registro_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),
  CONSTRAINT solicitudes_registro_revisado_por_fkey FOREIGN KEY (revisado_por) REFERENCES public.usuarios(id)
);
CREATE TABLE public.usuarios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  empresa_id uuid,
  nombre_completo text NOT NULL,
  email text NOT NULL UNIQUE,
  contraseña_hash text NOT NULL,
  rol text NOT NULL CHECK (rol = ANY (ARRAY['superadmin'::text, 'admin'::text, 'empleado'::text])),
  telefono character varying,
  avatar_url text,
  estado boolean DEFAULT true,
  creado_en timestamp with time zone DEFAULT now(),
  ultimo_login timestamp with time zone,
  actualizado_en timestamp with time zone DEFAULT now(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas(id)
);