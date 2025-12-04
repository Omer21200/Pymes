# Configuración de Supabase para Pymes2

## 1. Configurar credenciales

1. Ve a tu proyecto en Supabase Dashboard
2. Navega a **Settings** → **API**
3. Copia los siguientes valores:
   - **Project URL** (ej: `https://abcd1234.supabase.co`)
   - **anon public key**

4. Pega estos valores en `lib/config/supabase_config.dart`:
```dart
const String supabaseUrl = 'TU-PROJECT-URL-AQUI';
const String supabaseAnonKey = 'TU-ANON-KEY-AQUI';
```

## 2. Configurar Bucket de Storage

### Crear bucket (si no existe)
1. Ve a **Storage** en el Dashboard
2. Crea un bucket llamado `fotos`
3. **IMPORTANTE**: Marca como **público** (Public bucket = ON) para que las imágenes sean accesibles sin autenticación
4. Si el bucket ya existe y no es público, ve a Storage → fotos → Configuration → Make public

### Crear carpetas dentro del bucket
Dentro del bucket `fotos`, crea las siguientes carpetas:
- `empresas/` - para logos de empresas
- `empleados/` - para fotos de empleados

### Configurar políticas (Policies)

#### Política 1: Permitir subida (INSERT)
1. Ve a **Storage** → `fotos` → **Policies** → **New Policy**
2. Selecciona: **"For full customization"** → **Create a policy from scratch**
3. Configura:
   - **Policy name**: `Permitir subida autenticada`
   - **Allowed operation**: `INSERT`
   - **Policy definition**: 
     ```sql
     authenticated
     ```
   - **Target roles**: Deja por defecto o selecciona `authenticated`
4. Click **Save**

#### Política 2: Permitir lectura pública (SELECT)
1. Ve a **Storage** → `fotos` → **Policies** → **New Policy**
2. Selecciona: **"For full customization"** → **Create a policy from scratch**
3. Configura:
   - **Policy name**: `Permitir lectura pública`
   - **Allowed operation**: `SELECT`
   - **Policy definition**: 
     ```sql
     true
     ```
     (O usa `authenticated` si quieres restringir solo a usuarios logueados)
4. Click **Save**

#### (Opcional) Política 3: Permitir actualización (UPDATE)
Si necesitas actualizar archivos:
- **Policy name**: `Permitir actualización autenticada`
- **Allowed operation**: `UPDATE`
- **Policy definition**: `authenticated`

#### (Opcional) Política 4: Permitir eliminación (DELETE)
Si necesitas eliminar archivos:
- **Policy name**: `Permitir eliminación super admin`
- **Allowed operation**: `DELETE`
- **Policy definition**: 
  ```sql
  (auth.jwt() ->> 'role'::text) = 'SUPER_ADMIN'::text
  ```

## 3. Verificar Base de Datos

Asegúrate de haber ejecutado el script SQL en `lib/bases.txt` para crear todas las tablas y políticas RLS.

### Verificar usuario SUPER_ADMIN

Ejecuta en el **SQL Editor** de Supabase:

```sql
-- Ver usuario creado
SELECT id, email, created_at
FROM auth.users
WHERE email = 'omerbenitez2000@gmail.com';

-- Ver perfil del usuario
SELECT p.id, p.rol, p.nombres, p.apellidos, p.empresa_id
FROM public.profiles p
WHERE p.id = (
    SELECT id FROM auth.users WHERE email = 'omerbenitez2000@gmail.com'
);
```

Si el perfil no existe, créalo:

```sql
INSERT INTO public.profiles (id, rol, empresa_id, nombres, apellidos)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'omerbenitez2000@gmail.com'),
  'SUPER_ADMIN',
  null,
  'Super',
  'Admin'
);
```

## 4. Ejecutar la aplicación

```powershell
# Instalar dependencias
flutter pub get

# Limpiar build anterior
flutter clean
flutter pub get

# Ejecutar
flutter run
```

## 5. Uso

1. **Login**: Usa las credenciales del usuario SUPER_ADMIN
2. **Crear Empresa**: 
   - Ve a la pantalla de creación de empresas
   - Sube un logo (obligatorio)
   - Llena los campos (solo nombre es obligatorio)
   - Latitud y Longitud son opcionales (formato: -4.0086, -79.2089)
3. **Ver Empresas**: La lista se actualiza automáticamente después de crear una empresa
4. **Eliminar Empresa**: Click en el icono de eliminar y confirma

## Notas importantes

- ⚠️ **NO expongas la `service_role` key en el código del cliente**
- ✅ Las políticas RLS protegen los datos según el rol del usuario
- ✅ Los archivos se suben a `fotos/empresas/` con un timestamp único
- ✅ Las URLs de las imágenes son públicas (si configuraste el bucket como público)
