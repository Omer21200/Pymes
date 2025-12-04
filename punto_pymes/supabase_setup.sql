-- ############################################################
-- === 0. LIMPIEZA TOTAL (INCLUYE DROP CASCADE PARA EVITAR ERRORES) ===
-- ############################################################

DROP FUNCTION IF EXISTS public.handle_user_confirmed() CASCADE;
DROP TRIGGER IF EXISTS trg_sync_profile_jwt ON public.profiles;
DROP FUNCTION IF EXISTS public.sync_profile_to_jwt();
DROP FUNCTION IF EXISTS public.create_company_and_admin_request(text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.register_employee_rpc(text, text, text, text);
DROP FUNCTION IF EXISTS public.register_admin_request_rpc(text, text);
DROP FUNCTION IF EXISTS public.create_admin_request_for_company(text, uuid, text, text, text);
DROP FUNCTION IF EXISTS public.obtener_horario_esperado(uuid, date);
DROP FUNCTION IF EXISTS public.es_feriado(uuid, date);
DROP FUNCTION IF EXISTS public.get_asistencias_con_estado(uuid, uuid, date, date);

-- Eliminamos tablas (si deseas reiniciar el esquema completamente)
DROP TABLE IF EXISTS public.horarios_departamento CASCADE;
DROP TABLE IF EXISTS public.feriados CASCADE;
DROP TABLE IF EXISTS public.asistencias CASCADE;
DROP TABLE IF EXISTS public.empleados CASCADE;
DROP TABLE IF EXISTS public.departamentos CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.empresas CASCADE;
DROP TABLE IF EXISTS public.roles CASCADE;
DROP TABLE IF EXISTS public.admin_registration_requests CASCADE;
DROP TABLE IF EXISTS public.registration_requests CASCADE;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

---
---

-- ############################################################
-- === 1. CREACIÓN DE TABLAS PRINCIPALES ===
-- ############################################################

CREATE TABLE public.roles (
  id serial primary key,
  nombre text unique not null
);
INSERT INTO public.roles (nombre) VALUES ('SUPER_ADMIN'), ('ADMIN_EMPRESA'), ('EMPLEADO') ON CONFLICT (nombre) DO NOTHING;

CREATE TABLE public.empresas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  ruc text unique,
  codigo_acceso_empleado text unique not null, 
  direccion text,
  telefono text,
  correo text,
  empresa_foto_url text,
  latitud numeric(10,6),
  longitud numeric(10,6),
  created_at timestamp default now()
);

CREATE TABLE public.admin_registration_requests (
    email text PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    access_code text UNIQUE NOT NULL, 
    nombres text NOT NULL,
    apellidos text NOT NULL,
    created_at timestamp default now()
);

-- MODIFICACIÓN: Añadimos nombres y apellidos para el registro de Empleados
CREATE TABLE public.registration_requests (
  email text PRIMARY KEY,
  company_id uuid NOT NULL,
  code text NOT NULL, 
  nombres text, -- AÑADIDO
  apellidos text, -- AÑADIDO
  created_at timestamptz DEFAULT now()
);

CREATE TABLE public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  rol text not null check (rol in ('SUPER_ADMIN','ADMIN_EMPRESA','EMPLEADO')),
  empresa_id uuid references public.empresas(id) on delete set null,
  nombres text,
  apellidos text,
  foto_url text,
  company text, 
  created_at timestamp default now(),
  updated_at timestamp default now()
);

CREATE TABLE public.departamentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  descripcion text,
  created_at timestamp default now()
);

CREATE TABLE public.empleados (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  departamento_id uuid references public.departamentos(id) on delete set null,
  nombres text,
  apellidos text,
  cedula text unique,
  correo text unique,
  estado text default 'activo',
  registro_latitud numeric(10,6),
  registro_longitud numeric(10,6),
  telefono text, -- AÑADIDO
  direccion text, -- AÑADIDO
  created_at timestamp default now(),
  CONSTRAINT empleados_user_id_unique UNIQUE (user_id)
);

CREATE TABLE public.asistencias (
  id uuid primary key default gen_random_uuid(),
  empleado_id uuid not null references public.empleados(id) on delete cascade,
  fecha date not null default current_date,
  hora_entrada time,
  hora_salida time,
  latitud numeric(10,6),
  longitud numeric(10,6),
  foto_url text,
  estado text default 'pendiente',
  observacion text,
  created_at timestamp default now()
);

CREATE TABLE public.horarios_departamento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  departamento_id uuid NOT NULL REFERENCES public.departamentos(id) ON DELETE CASCADE,
  lunes boolean DEFAULT true,
  martes boolean DEFAULT true,
  miercoles boolean DEFAULT true,
  jueves boolean DEFAULT true,
  viernes boolean DEFAULT true,
  sabado boolean DEFAULT false,
  domingo boolean DEFAULT false,
  hora_entrada time NOT NULL DEFAULT '08:00:00',
  hora_salida time NOT NULL DEFAULT '17:00:00',
  tolerancia_entrada_minutos int DEFAULT 10,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  CONSTRAINT unique_horario_activo_por_departamento UNIQUE (departamento_id)
);

CREATE TABLE public.feriados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
  fecha date NOT NULL,
  nombre text NOT NULL,
  tipo text DEFAULT 'nacional' CHECK (tipo IN ('nacional', 'local', 'puente', 'recuperable')),
  recuperable boolean DEFAULT false,
  created_at timestamp DEFAULT now(),
  UNIQUE(empresa_id, fecha)
);

---

-- ############################################################
-- === 2. FUNCIONES DE REGISTRO SEGURO Y PERFIL ===
-- ############################################################

-- 2.1) RPC para EMPLEADOS (ACTUALIZADA: Recibe y guarda nombres/apellidos)
CREATE OR REPLACE FUNCTION public.register_employee_rpc(
    p_email text,
    p_code text,
    p_nombres text, 
    p_apellidos text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT id INTO v_empresa_id FROM public.empresas
    WHERE codigo_acceso_empleado = p_code;

    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Código de empresa inválido o no existe.';
    END IF;

    -- Guarda nombres y apellidos en el ticket
    INSERT INTO public.registration_requests (email, company_id, code, nombres, apellidos)
    VALUES (p_email, v_empresa_id, p_code, p_nombres, p_apellidos)
    ON CONFLICT (email) DO UPDATE 
        SET company_id = EXCLUDED.company_id, 
            code = EXCLUDED.code, 
            nombres = EXCLUDED.nombres, 
            apellidos = EXCLUDED.apellidos,
            created_at = now(); 

    RETURN TRUE;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error en register_employee_rpc: %', SQLERRM;
        RETURN FALSE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.register_employee_rpc(text, text, text, text) TO anon, authenticated;


-- 2.3) RPC para ADMINISTRADORES (Sin cambios, el Admin usa admin_registration_requests para nombres)
CREATE OR REPLACE FUNCTION public.register_admin_request_rpc(
    p_email text,
    p_access_code text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    req record;
BEGIN
    SELECT * INTO req FROM public.admin_registration_requests
    WHERE email = p_email AND access_code = p_access_code;

    IF NOT found THEN
        RAISE EXCEPTION 'Correo o Código de Acceso de Administrador inválido.';
    END IF;

    -- Los campos nombres/apellidos quedan NULL en registration_requests, 
    -- pero el trigger sabe dónde buscarlos (admin_registration_requests).
    INSERT INTO public.registration_requests (email, company_id, code)
    VALUES (p_email, req.empresa_id, p_access_code)
    ON CONFLICT (email) DO UPDATE 
        SET company_id = EXCLUDED.company_id, code = EXCLUDED.code, created_at = now(); 

    RETURN TRUE;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error en register_admin_request_rpc: %', SQLERRM;
        RETURN FALSE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.register_admin_request_rpc(text, text) TO anon, authenticated;


-- 2.4) Función handle_user_confirmed (CORREGIDA: Inserta a TODOS los usuarios con empresa_id en empleados)
CREATE OR REPLACE FUNCTION public.handle_user_confirmed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  req record;
  admin_req record;
  v_rol text := 'EMPLEADO';
  v_empresa_id uuid := NULL;
  v_nombres text := NULL;
  v_apellidos text := NULL;
BEGIN
  -- 1. Solo procede si el usuario ha sido confirmado
  IF (TG_OP = 'INSERT' AND NEW.confirmed_at IS NOT NULL) OR
     (TG_OP = 'UPDATE' AND OLD.confirmed_at IS NULL AND NEW.confirmed_at IS NOT NULL) THEN

    -- 2. Buscar solicitud de registro (Empleado o Admin)
    SELECT * INTO req FROM public.registration_requests WHERE email = NEW.email LIMIT 1;

    IF found THEN
        v_empresa_id := req.company_id;
        v_nombres := req.nombres;  -- Nombres de Empleado (si los envió)
        v_apellidos := req.apellidos; -- Apellidos de Empleado (si los envió)

        -- 3. Determinar si es Administrador y sobrescribir nombres
        SELECT * INTO admin_req FROM public.admin_registration_requests 
        WHERE email = NEW.email AND access_code = req.code AND empresa_id = req.company_id;

        IF found THEN
            v_rol := 'ADMIN_EMPRESA';
            -- Para admins, los nombres se toman de la tabla de pre-registro (la fuente de verdad)
            v_nombres := admin_req.nombres;
            v_apellidos := admin_req.apellidos;
        END IF;

        -- 4. INSERTAR/ACTUALIZAR PROFILES
        INSERT INTO public.profiles (id, rol, empresa_id, nombres, apellidos, created_at, updated_at)
        VALUES (NEW.id, v_rol, v_empresa_id, v_nombres, v_apellidos, now(), now())
        ON CONFLICT (id) DO UPDATE
            SET rol = EXCLUDED.rol,
                empresa_id = COALESCE(public.profiles.empresa_id, excluded.empresa_id),
                nombres = COALESCE(public.profiles.nombres, excluded.nombres),
                apellidos = COALESCE(public.profiles.apellidos, excluded.apellidos),
                updated_at = now();

        -- 5. INSERTAR EN EMPLEADOS (AHORA PARA ADMINS Y EMPLEADOS)
        -- Si hay una empresa asociada, SIEMPRE se inserta en empleados.
        IF v_empresa_id IS NOT NULL THEN
            INSERT INTO public.empleados (user_id, empresa_id, nombres, apellidos, correo)
            VALUES (NEW.id, v_empresa_id, v_nombres, v_apellidos, NEW.email)
            ON CONFLICT (user_id) DO NOTHING;
        END IF;

        -- 6. Limpiar tablas
        DELETE FROM public.registration_requests WHERE email = NEW.email;
        DELETE FROM public.admin_registration_requests WHERE email = NEW.email;
    ELSE
      -- Si no hay solicitud, asigna rol por defecto
      INSERT INTO public.profiles (id, rol, created_at, updated_at)
      VALUES (NEW.id, 'EMPLEADO', now(), now()) 
      ON CONFLICT (id) DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- EL RESTO DE TRIGGERS, JWT SYNC Y RLS NO REQUIEREN CAMBIOS



-- 2.5) Sincronización JWT (Robusta: Captura errores para no romper el flujo de auth)
CREATE OR REPLACE FUNCTION public.sync_profile_to_jwt()
RETURNS trigger AS $$
BEGIN
  BEGIN
    UPDATE auth.users
    SET raw_app_meta_data = 
      COALESCE(raw_app_meta_data, '{}'::jsonb) || 
      jsonb_build_object('role', NEW.rol, 'empresa_id', NEW.empresa_id::text)
    WHERE id = NEW.id;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error during JWT sync for user %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2.6) Triggers
CREATE TRIGGER trg_sync_profile_jwt
AFTER INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_to_jwt();

-- TRIGGER DE INSERT CORREGIDO: Se dispara en cualquier INSERT, la función comprueba confirmed_at
CREATE TRIGGER trigger_handle_user_confirmed_insert
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_user_confirmed();

-- TRIGGER DE UPDATE (al confirmar email)
CREATE TRIGGER trigger_handle_user_confirmed_update
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (old.confirmed_at IS NULL AND new.confirmed_at IS NOT NULL)
  EXECUTE PROCEDURE public.handle_user_confirmed();


---

-- ############################################################
-- === 3. FUNCIÓN DE SUPER ADMIN Y PERMISOS ===
-- ############################################################

CREATE OR REPLACE FUNCTION public.create_company_and_admin_request(
    p_nombre_empresa text,
    p_codigo_acceso_empleado text,
    p_email_admin text,
    p_codigo_admin text,
    p_nombres_admin text,
    p_apellidos_admin text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    IF (auth.jwt() -> 'app_meta_data' ->> 'role') <> 'SUPER_ADMIN' THEN
        RAISE EXCEPTION 'Acceso denegado: Solo Super Admin puede crear empresas y admins.';
    END IF;

    INSERT INTO public.empresas (nombre, codigo_acceso_empleado)
    VALUES (p_nombre_empresa, p_codigo_acceso_empleado)
    RETURNING id INTO v_empresa_id;

    INSERT INTO public.admin_registration_requests (email, empresa_id, access_code, nombres, apellidos)
    VALUES (p_email_admin, v_empresa_id, p_codigo_admin, p_nombres_admin, p_apellidos_admin);

    RETURN v_empresa_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_company_and_admin_request(text, text, text, text, text, text) TO authenticated;

-- ==================================================
-- RPC: Pre-registra un administrador para una empresa
-- Nombre esperado por el cliente: create_admin_request_for_company
-- ==================================================
CREATE OR REPLACE FUNCTION public.create_admin_request_for_company(
  p_email text,
  p_empresa_id uuid,
  p_access_code text,
  p_nombres text,
  p_apellidos text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Solo Super Admin puede crear estas solicitudes desde el backend
  IF (auth.jwt() -> 'app_meta_data' ->> 'role') <> 'SUPER_ADMIN' THEN
    RAISE EXCEPTION 'Acceso denegado: Solo Super Admin puede pre-registrar admins para una empresa.';
  END IF;

  INSERT INTO public.admin_registration_requests (email, empresa_id, access_code, nombres, apellidos)
  VALUES (p_email, p_empresa_id, p_access_code, p_nombres, p_apellidos)
  ON CONFLICT (email) DO UPDATE
    SET empresa_id = EXCLUDED.empresa_id,
      access_code = EXCLUDED.access_code,
      nombres = EXCLUDED.nombres,
      apellidos = EXCLUDED.apellidos,
      created_at = now();

  RETURN TRUE;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'Error en create_admin_request_for_company: %', SQLERRM;
  RETURN FALSE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_admin_request_for_company(text, uuid, text, text, text) TO authenticated;

---

-- ############################################################
-- === 4. RLS y POLÍTICAS DE ACCESO ===
-- ############################################################

ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empleados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_departamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feriados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_registration_requests ENABLE ROW LEVEL SECURITY;

-- EMPRESAS
CREATE POLICY "superadmin_empresas_all" ON public.empresas FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');
CREATE POLICY "admin_empresas_own" ON public.empresas FOR ALL USING (id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));
CREATE POLICY "public_ver_empresas" ON public.empresas FOR SELECT USING (auth.role() = 'authenticated');

-- PROFILES
CREATE POLICY "superadmin_profiles_all" ON public.profiles FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');
CREATE POLICY "user_own_profile" ON public.profiles FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "admin_ver_profiles_empresa" ON public.profiles FOR SELECT USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'ADMIN_EMPRESA' AND empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));
CREATE POLICY "user_insert_own_profile" ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());

-- EMPLEADOS
CREATE POLICY "superadmin_empleados" ON public.empleados FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');
CREATE POLICY "admin_gestion_empleados" ON public.empleados FOR ALL USING (empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));
CREATE POLICY "empleado_ver_propio" ON public.empleados FOR SELECT USING (user_id = auth.uid());

-- Permitir que un empleado actualice SOLO su propia fila (UPDATE)
CREATE POLICY "empleado_update_self" ON public.empleados FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ASISTENCIAS
CREATE POLICY "superadmin_asistencias" ON public.asistencias FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');
CREATE POLICY "admin_asistencias_empresa" ON public.asistencias FOR SELECT USING (empleado_id IN (SELECT id FROM public.empleados WHERE empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id')));
CREATE POLICY "empleado_gestion_asistencias" ON public.asistencias FOR ALL USING (empleado_id IN (SELECT id FROM public.empleados WHERE user_id = auth.uid()));

-- TABLAS DE REGISTRO AUXILIAR (Acceso denegado a todos)
CREATE POLICY "Deny all on registration_requests" ON public.registration_requests FOR ALL USING (false);
CREATE POLICY "Deny all on admin_registration_requests" ON public.admin_registration_requests FOR ALL USING (false);

-- ROLES (Catálogo)
CREATE POLICY "todos_leen_roles" ON public.roles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "superadmin_modifica_roles" ON public.roles FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN') WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');


---

-- ############################################################
-- === 5. FUNCIONES DE LÓGICA DE NEGOCIO Y VISTAS ===
-- ############################################################

-- Función Lógica: Es feriado
CREATE OR REPLACE FUNCTION public.es_feriado(p_empleado_id uuid, p_fecha date DEFAULT current_date)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.feriados f
    JOIN public.empleados e ON f.empresa_id IS NOT DISTINCT FROM e.empresa_id
    WHERE e.id = p_empleado_id AND f.fecha = p_fecha
  );
$$;

-- Función Lógica: Obtener horario esperado según día y departamento
CREATE OR REPLACE FUNCTION public.obtener_horario_esperado(p_empleado_id uuid, p_fecha date DEFAULT current_date)
RETURNS TABLE (hora_entrada_esperada time, hora_salida_esperada time, tolerancia_minutos int)
LANGUAGE plpgsql STABLE AS $$
DECLARE v_dia_semana text;
BEGIN
  v_dia_semana := LOWER(TO_CHAR(p_fecha, 'Day'));
  RETURN QUERY
  SELECT hd.hora_entrada, hd.hora_salida, hd.tolerancia_entrada_minutos
  FROM public.empleados e
  LEFT JOIN public.departamentos d ON e.departamento_id = d.id
  LEFT JOIN public.horarios_departamento hd ON hd.departamento_id = d.id
  WHERE e.id = p_empleado_id
    AND ((v_dia_semana LIKE 'monday%' AND hd.lunes) OR
         (v_dia_semana LIKE 'tuesday%' AND hd.martes) OR
         (v_dia_semana LIKE 'wednesday%' AND hd.miercoles) OR
         (v_dia_semana LIKE 'thursday%' AND hd.jueves) OR
         (v_dia_semana LIKE 'friday%' AND hd.viernes) OR
         (v_dia_semana LIKE 'saturday%' AND hd.sabado) OR
         (v_dia_semana LIKE 'sunday%' AND hd.domingo));
END;
$$;


-- Función segura para obtener asistencias
CREATE OR REPLACE FUNCTION public.get_asistencias_con_estado(
  p_empleado_id uuid DEFAULT NULL,
  p_empresa_id uuid DEFAULT NULL,
  p_fecha_desde date DEFAULT NULL,
  p_fecha_hasta date DEFAULT NULL
)
RETURNS TABLE (
  asistencia_id uuid, empleado_id uuid, empleado_nombre text, cedula text, departamento text,
  fecha date, hora_entrada time, hora_salida time, es_feriado boolean,
  estado_entrada text, estado_salida text, hora_entrada_esperada time, hora_salida_esperada time,
  tolerancia_minutos int
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_role text := (auth.jwt() -> 'app_metadata' ->> 'role');
  current_empresa_id text := (auth.jwt() -> 'app_metadata' ->> 'empresa_id');
BEGIN
  RETURN QUERY
  SELECT 
    a.id, a.empleado_id, e.nombres || ' ' || e.apellidos, e.cedula, d.nombre, a.fecha, a.hora_entrada, a.hora_salida,
    COALESCE(public.es_feriado(a.empleado_id, a.fecha), false),
    CASE 
      WHEN public.es_feriado(a.empleado_id, a.fecha) THEN 'Feriado'
      WHEN a.hora_entrada IS NULL AND a.fecha < current_date THEN 'Falta'
      WHEN a.hora_entrada IS NULL THEN 'Pendiente'
      WHEN a.hora_entrada <= (h.hora_entrada_esperada + (h.tolerancia_minutos * interval '1 minute')) THEN 'A tiempo'
      ELSE 'Tarde'
    END,
    CASE 
      WHEN public.es_feriado(a.empleado_id, a.fecha) THEN 'Feriado'
      WHEN a.hora_salida IS NOT NULL AND a.hora_salida < h.hora_salida_esperada - interval '30 minutes' THEN 'Salida temprana'
      WHEN a.hora_salida IS NOT NULL THEN 'Completa'
      WHEN a.hora_entrada IS NOT NULL AND a.fecha < current_date THEN 'Incompleta'
      ELSE 'Pendiente'
    END,
    h.hora_entrada_esperada, h.hora_salida_esperada, h.tolerancia_minutos
  FROM public.asistencias a
  JOIN public.empleados e ON a.empleado_id = e.id
  LEFT JOIN public.departamentos d ON e.departamento_id = d.id
  LEFT JOIN LATERAL public.obtener_horario_esperado(a.empleado_id, a.fecha) h ON true
  WHERE
    (p_empleado_id IS NULL OR a.empleado_id = p_empleado_id)
    AND (p_empresa_id IS NULL OR e.empresa_id = p_empresa_id)
    AND (p_fecha_desde IS NULL OR a.fecha >= p_fecha_desde)
    AND (p_fecha_hasta IS NULL OR a.fecha <= p_fecha_hasta)
    AND (
      current_role = 'SUPER_ADMIN'
      OR (current_role = 'ADMIN_EMPRESA' AND e.empresa_id::text = current_empresa_id)
      OR (current_role = 'EMPLEADO' AND e.user_id = auth.uid())
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_asistencias_con_estado(uuid, uuid, date, date) TO authenticated;

---

-- ############################################################
-- === 6. DATOS INICIALES (PARA CONFIGURAR EL SUPER ADMIN) ===
-- ############################################################

-- **¡ADVERTENCIA DE SUPER ADMIN!**
-- Estas sentencias deben ejecutarse *después* de crear el usuario 'omerbenitez2000@gmail.com' en el panel de Auth.


INSERT INTO public.profiles (id, rol, nombres, apellidos, empresa_id)
VALUES ((SELECT id FROM auth.users WHERE email = 'omerbenitez2000@gmail.com'), 'SUPER_ADMIN', 'Super', 'Admin', NULL)
ON CONFLICT (id) DO UPDATE SET rol = 'SUPER_ADMIN', empresa_id = NULL, updated_at = now();

UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'SUPER_ADMIN', 'empresa_id', null)
WHERE email = 'omerbenitez2000@gmail.com';


-- Feriados Ecuador 2025 (ejemplo)
INSERT INTO public.feriados (fecha, nombre, tipo) VALUES
('2025-01-01', 'Año Nuevo', 'nacional'),
('2025-02-24', 'Carnaval', 'nacional'),
('2025-02-25', 'Carnaval', 'nacional'),
('2025-04-18', 'Viernes Santo', 'nacional'),
('2025-05-01', 'Día del Trabajo', 'nacional'),
('2025-05-24', 'Batalla de Pichincha', 'nacional'),
('2025-08-10', 'Primer Grito de Independencia', 'nacional'),
('2025-10-09', 'Independencia de Guayaquil', 'nacional'),
('2025-11-02', 'Día de los Difuntos', 'nacional'),
('2025-11-03', 'Independencia de Cuenca', 'nacional'),
('2025-12-25', 'Navidad', 'nacional')
ON CONFLICT (empresa_id, fecha) DO NOTHING;