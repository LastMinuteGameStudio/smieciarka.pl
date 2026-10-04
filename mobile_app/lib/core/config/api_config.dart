/// Base URL of the FastAPI backend. Override with
/// `--dart-define=API_BASE_URL=...`, e.g. for a local backend.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.wkrynski.dev',
);
