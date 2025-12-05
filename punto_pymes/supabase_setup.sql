t, uuid, text, text, text) TO authenticated;

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


-- ############################################################
-- === POLÍTICAS PARA DEPARTAMENTOS Y HORARIOS ===
-- ############################################################

-- DEPARTAMENTOS
CREATE POLICY "superadmin_departamentos_all" ON public.departamentos
  FOR ALL
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');

CREATE POLICY "admin_gestion_departamentos" ON public.departamentos
  FOR ALL
  USING (empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));

CREATE POLICY "empleado_ver_departamentos" ON public.departamentos
  FOR SELECT
  USING (empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));


-- HORARIOS_DEPARTAMENTO
CREATE POLICY "superadmin_horarios_all" ON public.horarios_departamento
  FOR ALL
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');

CREATE POLICY "admin_gestion_horarios" ON public.horarios_departamento
  FOR ALL
  USING (departamento_id IN (SELECT d.id FROM public.departamentos d WHERE d.empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id')));

CREATE POLICY "empleado_ver_su_horario" ON public.horarios_departamento
  FOR SELECT
  USING (departamento_id = (SELECT e.departamento_id FROM public.empleados e WHERE e.user_id = auth.uid()));

-- ############################################################
-- === MÓDULO DE NOTICIAS Y COMUNICADOS ===
-- ############################################################

-- 1. Tabla Principal de Noticias
CREATE TABLE public.noticias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  creador_id uuid REFERENCES auth.users(id) ON DELETE SET NULL, -- Quién la escribió
  titulo text NOT NULL,
  contenido text NOT NULL, -- Puede soportar HTML simple o texto plano
  imagen_url text, -- Opcional: para portada de la noticia
  es_importante boolean DEFAULT false, -- TRUE = Se fija en el Inicio (Dashboard)
  tipo_audiencia text DEFAULT 'global' CHECK (tipo_audiencia IN ('global', 'departamento')),
  fecha_publicacion timestamp DEFAULT now(),
  created_at timestamp DEFAULT now()
);

-- 2. Tabla Intermedia: Para noticias dirigidas a departamentos específicos
CREATE TABLE public.noticias_departamentos (
  noticia_id uuid REFERENCES public.noticias(id) ON DELETE CASCADE,
  departamento_id uuid REFERENCES public.departamentos(id) ON DELETE CASCADE,
  PRIMARY KEY (noticia_id, departamento_id)
);

-- 3. Tabla de Lecturas (Para el sistema de notificaciones "No leído")
CREATE TABLE public.noticias_lecturas (
  noticia_id uuid REFERENCES public.noticias(id) ON DELETE CASCADE,
  empleado_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  leido_at timestamp DEFAULT now(),
  PRIMARY KEY (noticia_id, empleado_user_id)
);

ALTER TABLE public.noticias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.noticias_departamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.noticias_lecturas ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PARA NOTICIAS
CREATE POLICY "superadmin_noticias_all" ON public.noticias FOR ALL USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'SUPER_ADMIN');
CREATE POLICY "admin_gestion_noticias" ON public.noticias FOR ALL USING (empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id'));
CREATE POLICY "empleado_ver_noticias" ON public.noticias FOR SELECT
USING (
  empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id')
  AND (
    tipo_audiencia = 'global'
    OR id IN (
      SELECT nd.noticia_id
      FROM public.noticias_departamentos nd
      JOIN public.empleados e ON e.departamento_id = nd.departamento_id
      WHERE e.user_id = auth.uid()
    )
  )
);

-- POLÍTICAS PARA NOTICIAS_DEPARTAMENTOS
CREATE POLICY "admin_gestion_audiencia" ON public.noticias_departamentos FOR ALL
USING (EXISTS (SELECT 1 FROM public.noticias n WHERE n.id = noticia_id AND n.empresa_id::text = (auth.jwt() -> 'app_metadata' ->> 'empresa_id')));

CREATE POLICY "empleado_ver_audiencia" ON public.noticias_departamentos FOR SELECT USING (true);

-- POLÍTICAS PARA NOTICIAS_LECTURAS
CREATE POLICY "empleado_marcar_leido" ON public.noticias_lecturas FOR INSERT WITH CHECK (empleado_user_id = auth.uid());
CREATE POLICY "empleado_ver_leidas" ON public.noticias_lecturas FOR SELECT USING (empleado_user_id = auth.uid());


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

-- Función 1: Obtener noticias filtradas para el usuario actual
CREATE OR REPLACE FUNCTION public.get_noticias_usuario(p_limite int DEFAULT 20)
RETURNS TABLE (
  id uuid,
  titulo text,
  contenido text,
  imagen_url text,
  es_importante boolean,
  fecha_publicacion timestamp,
  tipo_audiencia text,
  leida boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  v_user_id uuid := auth.uid();
  v_departamento_id uuid;
BEGIN
  -- Obtener datos del empleado actual
  SELECT empresa_id, departamento_id INTO v_empresa_id, v_departamento_id
  FROM public.empleados WHERE user_id = v_user_id;

  RETURN QUERY
  SELECT
    n.id,
    n.titulo,
    n.contenido,
    n.imagen_url,
    n.es_importante,
    n.fecha_publicacion,
    n.tipo_audiencia,
    CASE WHEN nl.noticia_id IS NOT NULL THEN true ELSE false END as leida
  FROM public.noticias n
  LEFT JOIN public.noticias_lecturas nl ON n.id = nl.noticia_id AND nl.empleado_user_id = v_user_id
  WHERE
    n.empresa_id = v_empresa_id
    AND (
      n.tipo_audiencia = 'global'
      OR (n.tipo_audiencia = 'departamento' AND EXISTS (
          SELECT 1 FROM public.noticias_departamentos nd
          WHERE nd.noticia_id = n.id AND nd.departamento_id = v_departamento_id
      ))
    )
  ORDER BY
    n.es_importante DESC, -- Las importantes siempre arriba (pinned)
    n.fecha_publicacion DESC -- Luego las más recientes
  LIMIT p_limite;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_noticias_usuario(int) TO authenticated;


-- Función 2: Marcar noticia como leída
CREATE OR REPLACE FUNCTION public.marcar_noticia_leida(p_noticia_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.noticias_lecturas (noticia_id, empleado_user_id)
  VALUES (p_noticia_id, auth.uid())
  ON CONFLICT (noticia_id, empleado_user_id) DO NOTHING;
  RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.marcar_noticia_leida(uuid) TO authenticated;

-- ==================================================
-- FUNCIÓN PARA EL DASHBOARD DEL ADMIN
-- ==================================================
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_summary()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid := (auth.jwt() -> 'app_metadata' ->> 'empresa_id')::uuid;
    v_empleados_activos int;
    v_registros_hoy int;
    v_notificaciones int;
BEGIN
    -- Asegurarse de que el rol es ADMIN_EMPRESA
    IF (auth.jwt() -> 'app_metadata' ->> 'role') <> 'ADMIN_EMPRESA' THEN
        RAISE EXCEPTION 'Acceso denegado. Solo para administradores de empresa.';
    END IF;

    -- Conteo de empleados activos
    SELECT count(*) INTO v_empleados_activos FROM public.empleados WHERE empresa_id = v_empresa_id AND estado = 'activo';

    -- Conteo de registros de asistencia de hoy
    SELECT count(*) INTO v_registros_hoy FROM public.asistencias a
    JOIN public.empleados e ON a.empleado_id = e.id
    WHERE e.empresa_id = v_empresa_id AND a.fecha = current_date;

    -- Conteo de notificaciones (noticias) de la empresa
    SELECT count(*) INTO v_notificaciones FROM public.noticias WHERE empresa_id = v_empresa_id;

    RETURN json_build_object(
        'empleados_activos', v_empleados_activos,
        'registros_hoy', v_registros_hoy,
        'notificaciones_enviadas', v_notificaciones
    );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_summary() TO authenticated;


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

-- Elimina la política que obliga a autenticación y crea una pública (dev only)
DROP POLICY IF EXISTS "public_ver_empresas" ON public.empresas;
CREATE POLICY "public_ver_empresas" ON public.empresas FOR SELECT USING (true);
