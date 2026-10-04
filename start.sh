#!/usr/bin/env bash
# One-command local start: backend in Docker, then the Flutter app on a phone.
#   ./start.sh
# Asks for the two API keys once (saved to backend/.env), then starts everything.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/backend"
APP="$ROOT/mobile_app"
ENV_FILE="$BACKEND/.env"
API_PORT=8000
S3_PORT=4566

say() { printf '\n==> %s\n' "$1"; }
die() { printf '\nError: %s\n' "$1" >&2; exit 1; }

# Current value of KEY in .env, empty if unset.
env_value() {
  grep -E "^$1=" "$ENV_FILE" | head -n1 | cut -d= -f2- || true
}

# Writes KEY=value into .env, replacing the existing line.
set_env_value() {
  sed -i.bak "s|^$1=.*|$1=$2|" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
}

# This machine's LAN address, so phones and the emulator can reach the backend.
lan_ip() {
  local ip=""
  case "$(uname -s)" in
    Darwin) ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)" ;;
    Linux)  ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)" ;;
  esac
  printf '%s' "$ip"
}

say "Checking tools"
command -v docker >/dev/null || die "Docker is not installed. Install Docker Desktop (or Docker Engine on Linux) and run this again."
docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker and run this again."
docker compose version >/dev/null 2>&1 || die "'docker compose' is missing. Update Docker."

say "Backend configuration"
if [ ! -f "$ENV_FILE" ]; then
  cp "$BACKEND/.env.example" "$ENV_FILE"
  echo "Created backend/.env"
fi

for key in JINA_API_KEY GEMINI_API_KEY; do
  if [ -z "$(env_value "$key")" ]; then
    read -r -p "Paste $key and press Enter: " value
    [ -n "$value" ] || die "$key is required."
    set_env_value "$key" "$value"
  fi
done
echo "API keys are set."

IP="$(lan_ip)"
if [ -z "$IP" ]; then
  echo "Could not detect this computer's LAN address. Photos may not load on the phone."
  IP="localhost"
fi
export S3_PUBLIC_ENDPOINT="http://$IP:$S3_PORT"

say "Starting backend (first run takes a few minutes)"
(cd "$BACKEND" && docker compose up -d --build)

say "Waiting for the API"
for _ in $(seq 1 120); do
  if curl -fsS "http://localhost:$API_PORT/health" >/dev/null 2>&1; then
    echo "API is up at http://$IP:$API_PORT"
    break
  fi
  sleep 2
done
curl -fsS "http://localhost:$API_PORT/health" >/dev/null 2>&1 \
  || die "API did not start. Check logs with: cd backend && docker compose logs api"

say "Starting the app"
if ! command -v flutter >/dev/null; then
  echo "Flutter is not installed, so the app was not started."
  echo "Backend keeps running. Install Flutter, then run:"
  echo "  cd mobile_app && flutter pub get && flutter run --dart-define=API_BASE_URL=http://$IP:$API_PORT"
  exit 0
fi

cd "$APP"
flutter pub get
flutter run --dart-define=API_BASE_URL="http://$IP:$API_PORT"
