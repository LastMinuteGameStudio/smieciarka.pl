# Backend – uruchomienie

FastAPI + PostgreSQL (pgvector). Wyszukiwanie semantyczne ogłoszeń i filtry
nasłuchiwania, które powiadamiają o pasujących przedmiotach.

Opis architektury i modelu danych: [`../README.md`](../README.md). Ten plik
opisuje wyłącznie uruchomienie.

> **Zakres demo.** To nie jest pełny stack ze specyfikacji. Działa jedna baza
> PostgreSQL z pgvector. Nie ma Redisa, Celery, MinIO, PostGIS, FCM ani
> prawdziwej bramki SMS. Embeddingi i dopasowanie liczą się synchronicznie
> w żądaniu (15–30 ms, więc budżet 30 s ze specyfikacji nie jest zagrożony).
> Pełną listę braków znajdziesz w [Czego brakuje](#czego-brakuje).

---

## Czego potrzebujesz

| Wymagane | Po co |
| -------- | ----- |
| Docker + Docker Compose | PostgreSQL z pgvector, a w wariancie A także API |
| `JINA_API_KEY` | embeddingi i reranker, darmowy tier: https://jina.ai/embeddings |
| `GEMINI_API_KEY` | rozwijanie zapytań filtrów, darmowy tier: https://aistudio.google.com/apikey |
| Python 3.12+ | tylko dla [wariantu B](#wariant-b-venv-na-hoście) (testowane na 3.13) |

Oba klucze są darmowe i nie wymagają karty. Rejestracja zajmuje minutę.

**Bez kluczy backend nie wystartuje poprawnie.** Dopasowanie filtrów bez nich
nie działa — nie jest to opcjonalne ulepszenie, patrz
[Dlaczego potrzebne są klucze](#dlaczego-potrzebne-są-klucze).

Na NixOS [wariant A](#wariant-a-docker-zalecany) nie wymaga żadnych obejść —
Python i jego biblioteki siedzą w obrazie. Jedyne, co trzeba załatwić, to
[dostęp do Dockera](#dostęp-do-dockera). Obejście z `LD_LIBRARY_PATH` dotyczy
wyłącznie wariantu B, patrz [Notatki dla NixOS](#notatki-dla-nixos).

---

## Uruchomienie krok po kroku

Wszystkie komendy wykonuj w katalogu `backend/`.

Są dwie drogi. [Wariant A](#wariant-a-docker-zalecany) uruchamia w kontenerach
także API — jedna komenda, bez venva i bez obejść dla NixOS. [Wariant
B](#wariant-b-venv-na-hoście) trzyma API na hoście, co daje hot reload i
debugger w IDE. Konfiguracja z kroku 1 jest wspólna dla obu.

### 1. Konfiguracja

```bash
cp .env.example .env
```

Otwórz `.env` i wpisz dwa klucze:

```
JINA_API_KEY=jina_...
GEMINI_API_KEY=...
```

Reszta wartości ma sensowne domyślne i nie wymaga zmian.

### Wariant A: Docker (zalecany)

```bash
docker compose up -d --build
```

To wszystko. Dokumentacja: http://localhost:8000/docs

Compose podnosi trzy serwisy w ustalonej kolejności:

| Serwis | Rola |
| ------ | ---- |
| `postgres` | PostgreSQL 16 z pgvector, port `5432`, dane w wolumenie `pgdata` |
| `migrate` | jednorazowo `alembic upgrade head`, potem kończy z kodem 0 |
| `api` | uvicorn na porcie `8000` |

`api` startuje dopiero, gdy `postgres` jest `healthy`, a `migrate` zakończy się
sukcesem, więc API nigdy nie obsługuje żądań na nieaktualnym schemacie.
`migrate` jest idempotentny — na bazie w stanie `head` nic nie robi.

Stan i logi:

```bash
docker compose ps            # api i postgres mają być (healthy)
docker compose logs -f api
```

Po zmianie kodu w `app/` przebuduj obraz: `docker compose up -d --build`.
Warstwa z zależnościami jest cache'owana, więc trwa to sekundy. Jeśli chcesz
hot reload bez przebudowy, użyj wariantu B.

Klucze z `.env` wstrzykuje compose przez `env_file`. **Obraz ich nie
zawiera** — `.env` jest w `.dockerignore`, żeby nie trafiły do warstw obrazu.
`DATABASE_URL` z `.env` wskazuje na `localhost` (dla wariantu B); compose
nadpisuje go na `postgres`, czyli nazwę serwisu w sieci kontenerów.

Migracje możesz też odpalić osobno, bez restartu API:

```bash
docker compose run --rm migrate
```

### Wariant B: venv na hoście

Potrzebny, jeśli chcesz hot reload albo debugger. Na NixOS wymaga ustawienia
`LD_LIBRARY_PATH` — patrz [Notatki dla NixOS](#notatki-dla-nixos).

**1. Środowisko Pythona**

```bash
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
```

**2. Baza danych** — tylko PostgreSQL, bez `api` i `migrate`:

```bash
docker compose up -d postgres
```

Sprawdź, że kontener jest zdrowy:

```bash
docker compose ps
```

W kolumnie `STATUS` powinno być `(healthy)`. Jeśli port 5432 jest zajęty przez
lokalny PostgreSQL, zatrzymaj go albo zmień mapowanie portu w
`docker-compose.yml` oraz `DATABASE_URL` w `.env`.

**3. Migracje**

```bash
./venv/bin/alembic upgrade head
```

Tworzy tabele i włącza rozszerzenie `vector` (nie trzeba robić tego ręcznie).

**4. Start API**

```bash
./venv/bin/uvicorn app.main:app --reload
```

Gotowe. Dokumentacja: http://localhost:8000/docs

> Nie mieszaj wariantów na raz: oba chcą portu `8000`. Jeśli `api` chodzi
> w kontenerze, zatrzymaj je (`docker compose stop api`) przed startem
> uvicorna na hoście.

---

## Sprawdzenie, czy działa

```bash
curl localhost:8000/health
```

Oczekiwane: `{"status":"ok"}`

### Logowanie

Bramka SMS nie jest podłączona. W trybie demo (`OTP_MOCK=true`) **kod to zawsze
`123456`** dla dowolnego numeru. Numer musi być w formacie E.164 (`+48...`).

```bash
# 1. rozpoczęcie logowania (nic nie wysyła, kod jest stały)
curl -X POST localhost:8000/auth/phone/start \
  -H 'Content-Type: application/json' \
  -d '{"phone_number":"+48600000000"}'

# 2. weryfikacja -> zwraca access_token i refresh_token
curl -X POST localhost:8000/auth/phone/verify \
  -H 'Content-Type: application/json' \
  -d '{"phone_number":"+48600000000","code":"123456"}'
```

Nowy numer rejestruje się automatycznie przy pierwszej weryfikacji. Access token
żyje 15 minut. W zapytaniach wymagających logowania dodaj nagłówek
`Authorization: Bearer <access_token>`.

### Pełny przepływ: ogłoszenie, wyszukiwanie, powiadomienie

```bash
TOKEN=<access_token>

# dodanie ogłoszenia
curl -X POST localhost:8000/listings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Rękawice bramkarskie","description":"Rozmiar 8",
       "location":{"lat":52.4064,"lng":16.9252},"location_label":"Poznań, Jeżyce"}'

# wyszukiwanie semantyczne (bez logowania)
curl -G localhost:8000/listings/search \
  --data-urlencode 'q=rzeczy do gry w piłkę nożną'

# filtr nasłuchiwania
curl -X POST localhost:8000/filters \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"query":"rzeczy do gry w piłkę nożną","area":{"type":"nationwide"}}'

# powiadomienia (pojawią się, gdy INNY użytkownik doda pasujące ogłoszenie)
curl localhost:8000/notifications -H "Authorization: Bearer $TOKEN"
```

Autor nie dostaje powiadomień o swoich własnych ogłoszeniach, więc do testu
dopasowania potrzebujesz dwóch numerów telefonu.

---

## Zatrzymanie i sprzątanie

Dwa różne cele: zrobić przerwę albo wrócić do stanu przed uruchomieniem.

### Przerwa (dane zostają)

```bash
docker compose stop
```

Zatrzymuje wszystkie kontenery. W wariancie B zatrzymaj dodatkowo uvicorn przez
`Ctrl+C` w jego terminalu — chodzi poza Dockerem, więc `stop` go nie dotyczy.

Powrót do pracy: `docker compose start` (albo `docker compose up -d`). Baza ma
nadal zmigrowany schemat i wszystkie dane, więc migracji nie powtarzasz.

### Czyszczenie samych danych

Jeśli chcesz wyrzucić ogłoszenia i konta z testów, ale zachować schemat, obraz
i venv:

```bash
docker compose exec postgres \
  psql -U smieciarka -d smieciarka \
  -c 'truncate notifications, watch_filters, listings, users cascade;'
```

Tabela `alembic_version` zostaje nietknięta, więc migracji też nie powtarzasz.
Kody OTP i refresh tokeny trzyma proces API w pamięci, nie baza — jeśli chcesz
unieważnić też sesje z testów, zrestartuj go: `docker compose restart api`
(wariant A) albo uvicorna na hoście (wariant B).

### Pełne usunięcie

Poniższe kroki **bezpowrotnie usuwają bazę i wszystkie dane**. Nie ma kopii
zapasowej i nie ma cofnięcia — wolumen `backend_pgdata` przestaje istnieć.
Wykonaj je tylko wtedy, gdy naprawdę chcesz wrócić do stanu sprzed
uruchomienia. Jeśli chodziło Ci jedynie o zatrzymanie serwera, użyj
`docker compose stop` z sekcji powyżej.

Kolejność ma znaczenie: najpierw zatrzymaj API na hoście, potem usuń kontenery,
na końcu pliki.

**1. Zatrzymaj uvicorn na hoście.** Dotyczy tylko wariantu B — w wariancie A
pomiń ten krok, bo API zatrzyma `down` z kroku 2. `Ctrl+C` w terminalu
z uvicornem. Jeśli uruchomiłeś go w tle, znajdź i zatrzymaj proces:

```bash
pgrep -af 'venv/bin/uvicorn'
kill <PID>
```

Zatrzymanie procesu nadrzędnego (`--reload`) zabiera ze sobą workera.
Sprawdzenie, że port jest wolny: `curl localhost:8000/health` ma zwrócić błąd
połączenia.

**2. Usuń kontenery, sieć i wolumen.**

```bash
docker compose down -v
```

Zabiera `postgres`, `migrate` i `api` razem z siecią `backend_default`. Flaga
`-v` usuwa dodatkowo wolumen `backend_pgdata` z bazą. Bez niej wolumen zostaje
i następne `up -d` wstanie ze starymi danymi.

**3. Usuń pliki wygenerowane lokalnie.**

```bash
rm -rf venv
rm .env
find . -name __pycache__ -type d -prune -exec rm -rf {} +
```

Wszystkie trzy są w `.gitignore`, więc repozytorium wygląda po tym tak jak po
`git clone`. Sprawdź: `git status` ma nie pokazywać nic nowego. W wariancie A
venva nie ma, więc zostaje `.env` i `__pycache__`.

> `.env` zawiera Twoje klucze API. Jeśli nie chcesz wpisywać ich ponownie,
> skopiuj go gdzieś przed usunięciem — ale poza katalog repozytorium, żeby nie
> trafił przypadkiem do commita.

**4. Opcjonalnie: obrazy Dockera.** Razem około 1,2 GB. Usuwaj tylko, jeśli
odzyskujesz miejsce — następne uruchomienie pobierze Postgresa na nowo
i przebuduje obraz API:

```bash
docker image rm smieciarka-backend:latest pgvector/pgvector:pg16
```

Sam obraz API możesz też przebudować bez usuwania czegokolwiek:
`docker compose build --no-cache api`.

Nie uruchamiaj `docker system prune` ani `docker volume prune` zamiast
powyższych komend. Te polecenia działają na całym demonie i usuwają także
kontenery oraz wolumeny innych projektów.

Na NixOS każdą komendę `docker` poprzedź `sg docker -c '...'`, jeśli bieżąca
sesja nie ma jeszcze grupy `docker` — patrz
[Dostęp do Dockera](#dostęp-do-dockera).

Nowe uruchomienie od zera: wróć do
[Uruchomienia krok po kroku](#uruchomienie-krok-po-kroku). Trzeba powtórzyć
wszystkie kroki, łącznie z migracjami — w wariancie A robi je za Ciebie serwis
`migrate`.

---

## Dostępne endpointy

Pełna, zawsze aktualna lista: `/docs`.

| Metoda | Ścieżka | Auth |
| ------ | ------- | ---- |
| POST | `/auth/phone/start` | – |
| POST | `/auth/phone/verify` | – |
| POST | `/auth/refresh` | – |
| POST | `/auth/logout` | – |
| GET | `/me` | tak |
| GET | `/listings/search?q=&lat=&lng=&radius=` | – |
| GET | `/listings/nearby?lat=&lng=&radius=` | – |
| GET | `/listings/{id}` | – |
| POST | `/listings` | tak |
| POST | `/listings/{id}/status` | autor |
| GET | `/filters` | tak |
| POST | `/filters` | tak |
| DELETE | `/filters/{id}` | tak |
| GET | `/notifications` | tak |
| POST | `/notifications/{id}/read` | tak |

`lat`/`lng` w odpowiedziach publicznych są **zaokrąglone do ~100 m**. Dokładne
współrzędne widzi tylko autor ogłoszenia — lokalizacja to zwykle czyjś adres
domowy. Jeśli frontend pokazuje pineskę, używaj `location_label` do opisu.

---

## Notatki dla NixOS

Dwie rzeczy działają inaczej niż na innych distro.

Pierwsza z nich — biblioteki systemowe — **dotyczy wyłącznie
[wariantu B](#wariant-b-venv-na-hoście)**. W wariancie A Python i jego
zależności żyją w obrazie zbudowanym na Debianie, więc problem nie istnieje
i nie ustawiasz niczego. Dostęp do Dockera trzeba załatwić w obu wariantach.

### Biblioteki systemowe dla pakietów Pythona

Skompilowane paczki z PyPI (`numpy`, które ciągnie `pgvector`) linkują się do
`libstdc++` i `libz` ze ścieżek, których na NixOS nie ma. Bez tego `pip install`
przejdzie, ale import wysypie się tak:

```
ImportError: libstdc++.so.6: cannot open shared object file
```

Ustaw `LD_LIBRARY_PATH` na ścieżki ze store. Nie wpisuj ich na sztywno — hashe
różnią się między maszynami. Wylicz je:

```bash
export LD_LIBRARY_PATH="$(nix-build '<nixpkgs>' -A stdenv.cc.cc.lib --no-out-link)/lib:$(nix-build '<nixpkgs>' -A zlib --no-out-link)/lib"
```

Ta zmienna musi być ustawiona dla **każdej** komendy używającej venv, czyli
`pip`, `alembic` i `uvicorn`. Najprościej wyeksportować ją raz na początku
sesji w terminalu.

> Uwaga: w store bywa 32-bitowy `zlib`. Jeśli dostaniesz
> `wrong ELF class: ELFCLASS32`, to znaczy, że `LD_LIBRARY_PATH` wskazuje na
> wariant 32-bitowy. Komenda powyżej zwraca poprawny, 64-bitowy.

Alternatywa, jeśli wolisz nie ustawiać zmiennej ręcznie: `nix-shell -p
stdenv.cc.cc.lib zlib` i praca wewnątrz tej powłoki.

### Dostęp do Dockera

Gniazdo Dockera wymaga uprawnień. Dodaj się do grupy:

```bash
sudo usermod -aG docker $USER
```

Zmiana grup działa dopiero w **nowej sesji logowania** — już otwarty terminal
nadal będzie dostawał `permission denied while trying to connect to the Docker
API`. Zamiast się przelogowywać możesz użyć:

```bash
sg docker -c 'docker compose up -d'
```

---

## Konfiguracja

Pełna lista z komentarzami: [`.env.example`](.env.example). Najważniejsze:

| Zmienna | Domyślnie | Opis |
| ------- | --------- | ---- |
| `DATABASE_URL` | localhost:5432 | połączenie z PostgreSQL |
| `JINA_API_KEY` | – | embeddingi + reranker (wymagane) |
| `GEMINI_API_KEY` | – | rozwijanie zapytań (wymagane) |
| `GEMINI_MODEL` | `gemini-flash-lite-latest` | patrz uwaga niżej |
| `EMBEDDING_PROVIDER` | `jina` | `jina` (1024 wymiary) lub `fastembed` (lokalnie, 384) |
| `MATCH_RERANK_THRESHOLD` | `0.10` | próg dopasowania filtra |
| `OTP_MOCK` | `true` | kod SMS to stałe `123456` |
| `MAX_FILTERS_PER_USER` | `10` | limit filtrów na konto |
| `LISTING_TTL_HOURS` | `72` | `expires_at` nowego ogłoszenia |

> **`GEMINI_MODEL`:** Google wycofuje identyfikatory modeli dla nowych kluczy
> bez zapowiedzi — `gemini-2.5-flash` zwraca już 404. Jeśli zobaczysz w logach
> `query expansion failed`, wylistuj dostępne modele i podmień wartość:
> ```bash
> curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY" \
>   | grep -o '"models/gemini[^"]*"'
> ```

### Tryb offline bez kluczy

Jest lokalny model (`fastembed`), ale ma inny wymiar wektora, więc wymaga
zmiany schematu i **psuje jakość dopasowania filtrów**. Tylko jeśli naprawdę
potrzebujesz pracy bez internetu:

```bash
# w .env: EMBEDDING_PROVIDER=fastembed, EMBEDDING_DIM=384
./venv/bin/alembic downgrade f810b33664ea
```

Wyszukiwanie będzie działać sensownie. Powiadomienia z filtrów — nie, bo
lokalny model nie pozwala oddzielić trafień od przypadkowych podobieństw
(mierzone: żaden próg nie rozdziela tych zbiorów).

---

## Dlaczego potrzebne są klucze

Nieoczywista rzecz, która decyduje o architekturze dopasowania.

Wynik podobieństwa cosinusowego z embeddingów **nie jest skalibrowany**: nie
istnieje stały próg, który oddziela trafienie od nietrafienia. Zmierzone na
zestawie testowym, najgorszy przypadek separacji: `-0.260` dla lokalnego
modelu MiniLM i `-0.007` dla `multilingual-e5-large`, czyli modelu zalecanego
w specyfikacji. Przy pierwotnym progu `0.55` pięć z sześciu ogłoszeń
z przykładu w głównym README nie powiadamiało w ogóle.

Dlatego dopasowanie ma dwa etapy:

1. **Prefiltr cosinusowy w Postgresie** nominuje kandydatów. pgvector dobrze
   *szereguje* (średnie AP 0.95), tylko nie umie postawić progu. Warunek
   obszaru (promień, cała Polska) wykonuje się w tym samym zapytaniu.
2. **Reranker decyduje.** Wyniki rerankera są skalibrowane, więc stały próg
   `0.10` ma sens: separacja `+0.041`.

Stąd wymagania, które inaczej wyglądałyby arbitralnie:

- **Rozwijanie zapytań jest obowiązkowe, nie opcjonalne.** Dla surowego
  zapytania reranker nie rozdziela zbiorów przy żadnym progu (`-0.116`).
  Dlatego potrzebny jest `GEMINI_API_KEY`. Rozwinięcie liczy się raz przy
  tworzeniu filtra i zapisuje w `watch_filters.expanded_query`, więc to
  kilkanaście wywołań LLM na całe demo, nie jedno na ogłoszenie. Próbowano
  zamiast tego szablonów zapytań — wszystkie zawiodły, bo zysk pochodzi
  z wiedzy o świecie, nie z formy zdania.
- **Reranker dostaje tylko tytuł ogłoszenia.** Dołączenie opisu wyraźnie
  rozmywa wynik: `Piłka nożna` dostaje 0.40, a `Piłka nożna Adidas, rozmiar 5`
  tylko 0.06 — mniej niż niezwiązany regał na książki.
- **Reranker nie jest symetryczny.** Skalibrowany jest wyłącznie kierunek
  „potrzeba jako zapytanie” (`+0.041` kontra `-0.215` odwrotnie), więc każdy
  kandydat wymaga osobnego wywołania. Lecą równolegle, maksymalnie 10 naraz.

Próg `0.10` jest skalibrowany na ręcznie zrobionym zestawie 18 ogłoszeń, nie na
prawdziwych danych. Zestaw `tests/matching_eval/` ze specyfikacji nie istnieje —
to pierwsza rzecz do zrobienia, jeśli dopasowanie zacznie się mylić.

---

## Czego brakuje

Względem specyfikacji w [`../README.md`](../README.md), świadomie pominięte
w wersji demo:

**Infrastruktura:** Redis, Celery (embeddingi liczą się w żądaniu), MinIO/S3,
PostGIS (odległość liczona wzorem haversine na kolumnach `lat`/`lng`), FCM i Web
Push, prawdziwa bramka SMS.

**Tabele:** `listing_images`, `regions`, `categories`, `device_tokens`.
W `listings` brakuje `image_caption`, `search_tsv`, `category_ids`, `region_ids`.

**Indeksy:** żadnego z sekcji 4 — brak HNSW, GiST i GIN. Przy obecnej skali
nie ma to znaczenia, ale trzeba je dodać przed produkcją.

**Funkcje:** tryb obszaru `regions` (są tylko `radius` i `nationwide`),
tagowanie kategoriami, weryfikacja strefy szarej przez LLM, opisy zdjęć modelem
vision, wyszukiwanie hybrydowe z RRF, automatyczne wygaszanie ogłoszeń
(`expires_at` jest ustawiane, ale nic go nie sprząta), paginacja kursorem.

**Endpointy:** `PATCH`/`DELETE` na ogłoszeniach, upload zdjęć, zgłoszenia do
moderacji, `PATCH` i podgląd filtrów, `/regions`, `/categories`, `/devices`,
eksport i usunięcie konta (RODO).

**Bezpieczeństwo** — do zrobienia przed wpuszczeniem prawdziwych numerów:
nie ma limitu prób kodu OTP (możliwy brute force), `POST /auth/logout` nie
unieważnia refresh tokenu, refresh tokeny nie są rotowane ani hashowane
w bazie, brak rate limitingu i CAPTCHA.

---

## Problemy

| Objaw | Przyczyna |
| ----- | --------- |
| `ImportError: libstdc++.so.6` | wariant B na NixOS, brak `LD_LIBRARY_PATH` — patrz wyżej |
| `wrong ELF class: ELFCLASS32` | `LD_LIBRARY_PATH` wskazuje 32-bitowy `zlib` |
| `permission denied ... Docker API` | brak grupy `docker` w tej sesji — użyj `sg docker -c '...'` |
| `RuntimeError: EMBEDDING_PROVIDER=jina but JINA_API_KEY is empty` | uzupełnij klucz w `.env`. W wariancie A po edycji `.env` zrób `docker compose up -d` — compose czyta go przy starcie kontenera |
| `query expansion failed` w logach | nieaktualny `GEMINI_MODEL` albo zły klucz; filtry powstaną, ale będą słabo dopasowywać |
| `expected 1024 dimensions, not 384` | zmieniono providera bez migracji — patrz [Tryb offline](#tryb-offline-bez-kluczy) |
| Filtr nie powiadamia | autor nie dostaje powiadomień o własnych ogłoszeniach; użyj drugiego numeru |
| `connection refused` na 5432 | kontener nie wstał: `docker compose ps` |
| `env file .env not found` przy `up` | nie zrobiłeś kroku 1: `cp .env.example .env` |
| `port is already allocated` na 8000 | uvicorn z wariantu B jeszcze chodzi; zatrzymaj go albo `docker compose stop api` |
| `api` czeka i nie startuje | `migrate` padł; zobacz `docker compose logs migrate` |
| Zmiana w `app/` nie działa w wariancie A | obraz trzyma kopię kodu: `docker compose up -d --build` |
