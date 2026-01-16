# NEXO — Documentación Técnica

Este documento complementa el README principal con la estructura del proyecto, la arquitectura, flujo de datos y pasos rápidos para desarrollar y analizar la app.

## Resumen rápido
- Frontend: Flutter (app multiplataforma).  
- Backend: Supabase (PostgREST, RPC, Storage).  
- Propósito: App de gestión de asistencia, notificaciones y administración para PYMES.

---

## Estructura del proyecto (resumida)
- `lib/`
  - `main.dart` — entrada de la app.
  - `theme.dart` — tokens y estilos globales.
  - `config/` — `supabase_config.dart` (URL y key públicas/anon).
  - `service/` — servicios centrales (ej. `supabase_service.dart`, `profile_service.dart`, `theme_provider.dart`).
  - `pages/` — pantalla por área (feature-first):
    - `admin_empresa/` (dashboards, departamentos, noticias, widgets)
    - `empleado/` (inicio, departamento, widgets: reloj, notificaciones)
    - `superadmin/` (funciones avanzadas de administración)
    - `login_page/`, `widgets/` compartidos
- `android/ ios/ macos/ linux/ web/ windows/` — carpetas generadas por Flutter.
- `test/` — pruebas (ejemplo `widget_test.dart`).
- `pubspec.yaml`, `README.md`, `supabase_setup.sql` en la raíz.

---

## Arquitectura y patrones
- Organización por características (feature-first).  
- Capa UI: `pages/*` y `widgets/*` con `StatefulWidget`/`StatelessWidget` y `setState()` para estado local.  
- Capa de servicios: `SupabaseService` (singleton) centraliza:
  - autenticación, consultas PostgREST, llamadas RPC, storage y helpers.
  - retorna `Map<String, dynamic>` y listas normalizadas para la UI.
- Estado compartido ligero: singletons/gestores estáticos (ej. `EcuadorTimeManager`) en vez de un store global (Provider/Riverpod).  
- Manejo de errores: try/catch en servicios; UI muestra `SnackBar` y estados de carga/error.  
- Logging: uso de `dart:developer.log` (migrado desde `print`) para registros estructurados.

---

## Flujo de datos típico
1. El usuario interactúa con la UI (tap, formulario).  
2. UI llama a métodos async en `SupabaseService` (ej. `getDepartamentosPorEmpresa`).  
3. `SupabaseService` ejecuta `.from(...)` o `.rpc(...)` y procesa la respuesta.  
4. UI recibe datos, normaliza y actualiza la vista con `setState()`.  
5. Para acciones que afecten a toda la app (por ejemplo hora sincronizada), se actualiza un manager estático (`EcuadorTimeManager`) que otros widgets consultan.

---

## Principales archivos y responsabilidades
- `lib/service/supabase_service.dart` — todas las operaciones con la BD y storage.
- `lib/pages/admin_empresa/widgets/admin_dashboard_view.dart` — vista de resumen admin.
- `lib/pages/empleado/widgets/hora_internet_ecuador.dart` — obtiene hora desde API pública y expone `EcuadorTimeManager`.
- `lib/pages/empleado/widgets/notification_card.dart` — tarjetas de notificaciones.
- `lib/theme.dart` — colores, tamaños y decoraciones compartidas.

---

## Lints y mejoras aplicadas (reciente)
- Reemplazadas llamadas a `withOpacity()` por `withAlpha(...)` para evitar la API obsoleta.  
- Evitado el uso de `BuildContext` a través de gaps async; se capturó `ScaffoldMessenger` después de `mounted` cuando fue necesario.  
- Se reemplazó `print()` por `dart:developer.log(...)` para mejor trazabilidad.

---

## Cómo ejecutar verificaciones rápidas (local)
- Analizar el proyecto:
```bash
flutter analyze
```

- Ejecutar tests (si existen):
```bash
flutter test
```

- Ejecutar la app en un dispositivo/emulador:
```bash
flutter run -d <device-id>
```

Nota: Asegúrate de tener configuradas las variables/keys de Supabase en `lib/config/supabase_config.dart` o mediante variables de entorno según tu flujo.

---

## Recomendaciones / próximos pasos
- Considerar un gestor de estado (Provider / Riverpod) si la app crece y el paso de props/estado con `setState()` complica la sincronización.  
- Centralizar la configuración de logging (envoltorio sobre `developer.log`) para distinguir entornos (dev/prod).  
- Añadir checks e2e básicos y más tests unitarios sobre `SupabaseService` (mock client).  
- Documentar RPCs usados en la base (nombres de funciones y parámetros) dentro de `supabase_setup.sql` o la Wiki.

---

¿Quieres que reemplace el `README.md` principal por este contenido o que deje éste como `README_DETAILED.md` (ya creado)? Puedo también abrir un PR con los cambios y ejecutar `flutter analyze` ahora si lo deseas.
