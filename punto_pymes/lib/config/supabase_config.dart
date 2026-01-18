// Configuración de Supabase.
// Reemplaza los placeholders con tus valores reales.
// Obtén estos valores en Supabase: Project Settings -> API.
// NO expongas la service_role key en el cliente, solo usa anon key.

const String supabaseUrl = 'https://pnhnmnhlwcrzlvkbcruu.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuaG5tbmhsd2Nyemx2a2JjcnV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3MjQzMzEsImV4cCI6MjA4MDMwMDMzMX0.1OJAL56XZJoPz_1Tl3EJBb2gYgWq2fyY9jwrz4uteas';

// Optional: URL to a Google Cloud Function (or any proxy) that returns a static map image for given coordinates.
// Example usage from the client: `$googleMapFunctionUrl?lat={lat}&lng={lng}&w={width}&h={height}`
// Leave empty if you prefer to use the built-in OpenStreetMap static tile service.
const String googleMapFunctionUrl = '';
