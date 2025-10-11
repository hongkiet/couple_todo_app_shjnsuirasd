class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bsiezefpommexehvftss.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzaWV6ZWZwb21tZXhlaHZmdHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MzEwNDksImV4cCI6MjA3NTAwNzA0OX0.VtXNNt0_Q0-XzL7wym111R1VDMLfXY4Ov6VkVh46k5c',
  );
}