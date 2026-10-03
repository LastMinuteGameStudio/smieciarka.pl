/// Base URL of the FastAPI backend. Override with
/// `--dart-define=API_BASE_URL=...`. 10.0.2.2 is the Android emulator's alias
/// for the host machine.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
