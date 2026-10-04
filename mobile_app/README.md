# UczciwaCena – aplikacja mobilna

Flutter. Ogłoszenia, alerty (filtry nasłuchiwania na mapie) i logowanie
numerem telefonu. Dane pochodzą z backendu FastAPI w katalogu `../backend`.

## Wymagania

- Flutter 3.x (Dart SDK zgodny z `pubspec.yaml`)
- Docker (OrbStack, Docker Desktop albo Colima) do backendu
- Klucze `JINA_API_KEY` i `GEMINI_API_KEY` do `backend/.env`

## 1. Backend

Szczegółowe instrukcje, w tym wariant z venvem na hoście, są w
[`../backend/docs/uruchomienie.md`](../backend/docs/uruchomienie.md). Skrót:

```bash
cd ../backend
cp .env.example .env        # wpisz JINA_API_KEY i GEMINI_API_KEY
docker compose up -d --build
curl localhost:8000/health  # {"status":"ok"}
```

Compose podnosi Postgresa z pgvector, magazyn zdjęć, jednorazowe migracje
i API na porcie 8000.

Pierwsze uruchomienie na pustej bazie: dodaj przykładowe ogłoszenia (wymaga
działającego API i `JINA_API_KEY`):

```bash
python3 scripts/seed_listings.py --base-url http://localhost:8000
```

Nie uruchamiaj seedera ponownie na tej samej bazie, bo doda duplikaty.

## 2. Połączenie aplikacji z backendem

Aplikacja czyta adres API z `--dart-define=API_BASE_URL=…`. Domyślnie
`http://10.0.2.2:8000`, czyli emulator Androida.

| Telefon / emulator | Jak połączyć | Parametr |
| ------------------ | ------------ | -------- |
| Emulator Androida | nic nie trzeba | domyślny `10.0.2.2:8000` |
| Android przez USB | `adb reverse tcp:8000 tcp:8000` | `http://localhost:8000` |
| Fizyczny telefon w tej samej sieci Wi‑Fi | adres komputera: `ipconfig getifaddr en1` | `http://<adres>:8000` |

Telefon i komputer muszą być w tej samej sieci, jeśli używasz adresu IP.
Zapora systemowa nie może blokować portu 8000.

## 3. Uruchomienie aplikacji

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<adres>:8000
```

Bez `--dart-define` aplikacja łączy się z `10.0.2.2:8000`.

## Logowanie w trybie demo

Bramka SMS nie jest podłączona. Numer w formacie `+48…` (aplikacja dokleja
prefiks sama), kod to zawsze `123456`.

Ogłoszenia są dostępne bez logowania („Kontynuuj bez logowania”). Alerty
wymagają zalogowania.

## Testy

```bash
flutter analyze
flutter test
```

## Znane ograniczenia

- Lokalizacja: wyszukiwanie ogłoszeń działa w promieniu 10 km od telefonu.
  Bez zgody na lokalizację używany jest punkt w Warszawie.
- Symulator iOS: wymaga `API_BASE_URL=http://localhost:8000` i wyjątku ATS
  dla HTTP, których jeszcze nie ma w projekcie.
- Orientacja jest zablokowana na pionową.
