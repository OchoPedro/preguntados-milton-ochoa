class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://thlyfinkbrafnamftsxo.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRobHlmaW5rYnJhZm5hbWZ0c3hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NjQ1ODQsImV4cCI6MjA5NzI0MDU4NH0.DyYXt7iALZ9ldYLmwj_wATXLpRoYlBYjVkF8mw0MwcI',
  );

  // La Claude API key solo se usa desde Edge Functions (servidor), no desde el cliente.
  static const String claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
}
