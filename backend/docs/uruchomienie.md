# Backend – uruchomienie

FastAPI + PostgreSQL (pgvector). Wyszukiwanie semantyczne ogłoszeń i filtry
nasłuchiwania, które powiadamiają o pasujących przedmiotach.

Ten plik opisuje wyłącznie uruchomienie. Co dokładnie jest zbudowane, jak
działa dopasowanie i czego brakuje względem specyfikacji:
[`stan-obecny.md`](stan-obecny.md). Docelowa specyfikacja (nie stan kodu):
[`../../README.md`](../../README.md).

> **Zakres demo.** To nie jest pełny stack ze specyfikacji. Działa PostgreSQL
> z pgvector i magazyn obiektów po S3. Nie ma Redisa, Celery, PostGIS, FCM ani
> prawdziwej bramki SMS. Embeddingi, przetwarzanie zdjęć i dopasowanie liczą
> się synchronicznie w żądaniu. Pełna lista braków:
> [`stan-obecny.md`](stan-obecny.md#czego-brakuje-względem-specyfikacji).

---

## Czego potrzebujesz

| Wymagane | Po co |
| -------- | ----- |
| Docker + Docker Compose | PostgreSQL z pgvector i magazyn S3, a w wariancie A także API |
| `JINA_API_KEY` | embeddingi i reranker, darmowy tier: https://jina.ai/embeddings |
| `GEMINI_API_KEY` | rozwijanie zapytań filtrów i opisy zdjęć, darmowy tier: https://aistudio.google.com/apikey |
| Python 3.12+ | tylko dla [wariantu B](#wariant-b-venv-na-hoście) (testowane na 3.13) |

Oba klucze są darmowe i nie wymagają karty. Rejestracja zajmuje minutę.

**Bez kluczy backend nie wystartuje poprawnie.** Dopasowanie filtrów bez nich
nie działa — nie jest to opcjonalne ulepszenie, patrz
[`stan-obecny.md`](stan-obecny.md#dlaczego-klucze-są-wymagane).

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

Compose podnosi cztery serwisy w ustalonej kolejności:

| Serwis | Rola |
| ------ | ---- |
| `postgres` | PostgreSQL 16 z pgvector, port `5432`, dane w wolumenie `pgdata` |
| `s3` | magazyn zdjęć po S3, port `4566`, dane w wolumenie `s3data` |
| `migrate` | jednorazowo `alembic upgrade head`, potem kończy z kodem 0 |
| `api` | uvicorn na porcie `8000` |

`api` startuje dopiero, gdy `postgres` i `s3` są `healthy`, a `migrate`
zakończy się sukcesem, więc API nigdy nie obsługuje żądań na nieaktualnym
schemacie. `migrate` jest idempotentny — na bazie w stanie `head` nic nie robi.
Bucket na zdjęcia tworzy samo API przy pierwszym uploadzie, nie ma osobnego
zadania inicjującego.

> **Dlaczego `s3`, a nie MinIO.** Specyfikacja nazywa MinIO i kod działa
> z MinIO bez zmian, ale MinIO nie publikuje już obrazu do anonimowego
> pobrania. W compose stoi więc LocalStack przypięty do tagu `4` (`latest`
> wymaga licencji). Szczegóły i instrukcja powrotu na MinIO:
> [`stan-obecny.md`](stan-obecny.md#minio-kontra-localstack).

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

**2. Baza danych i magazyn zdjęć** — bez `api` i `migrate`:

```bash
docker compose up -d postgres s3
```

W `.env` ustaw wtedy `S3_ENDPOINT=http://localhost:4566`
i zostaw `S3_PUBLIC_ENDPOINT` puste — poza siecią kontenerów oba adresy są
takie same i podpis presigned URL wyjdzie poprawny.

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

### Zdjęcia

Zdjęcia dodaje autor ogłoszenia, po jednym na żądanie, maksymalnie 6 na
ogłoszenie. Odpowiedź to całe ogłoszenie z aktualną listą zdjęć.

```bash
LISTING=<id ogłoszenia>

# upload (multipart). JPEG, PNG, WebP, HEIC/HEIF, do 10 MB
curl -X POST localhost:8000/listings/$LISTING/images \
  -H "Authorization: Bearer $TOKEN" \
  -F 'file=@zdjecie.jpg;type=image/jpeg'

# usunięcie konkretnego zdjęcia
curl -X DELETE localhost:8000/listings/$LISTING/images/<id zdjęcia> \
  -H "Authorization: Bearer $TOKEN"
```

W odpowiedzi każde zdjęcie ma `url`, `thumb_url` i `caption`. Adresy są
podpisane i wygasają po `S3_PRESIGN_TTL` (domyślnie godzina), więc pobieraj je
z aktualnej odpowiedzi, a nie z zapisanego linku.

Upload trwa około 3 s, bo w jednym żądaniu dzieje się konwersja do WebP, zapis
dwóch plików, opis zdjęcia modelem vision, ponowny embedding ogłoszenia
i powtórne dopasowanie do filtrów. To nie jest zawieszenie.

Sprawdzenie, że EXIF ze współrzędnymi GPS faktycznie zniknął — wgrany plik
kontra to, co leży w magazynie:

```bash
curl -s "<url z odpowiedzi>" -o stored.webp
python3 -c "
from PIL import Image
for name in ('zdjecie.jpg', 'stored.webp'):
    exif = Image.open(name).getexif()
    print(name, 'tagi:', sorted(exif.keys()), 'GPS:', dict(exif.get_ifd(0x8825)))
"
```

Dla pliku w magazynie oba mają być puste: `tagi: [] GPS: {}`.

Zawartość bucketa można podejrzeć bezpośrednio:

```bash
docker compose exec s3 awslocal s3 ls --recursive s3://listing-images/
```

Opis zdjęcia wchodzi do tekstu, z którego liczony jest embedding, więc
ogłoszenie staje się znajdowalne po tym, co widać na obrazku — także wtedy,
gdy tytuł o tym nie mówi. Bez `GEMINI_API_KEY` albo przy
`VISION_ENABLED=false` zdjęcia nadal się wgrywają, tylko nie wnoszą nic do
wyszukiwania.

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
  -c 'truncate notifications, listing_images, watch_filters, listings, users cascade;'
```

To czyści bazę, ale **nie magazyn** — pliki zdjęć zostają w buckecie jako
śmieci bez wiersza. Usuń je osobno:

```bash
docker compose exec s3 awslocal s3 rm --recursive s3://listing-images/
```

Tabela `alembic_version` zostaje nietknięta, więc migracji też nie powtarzasz.
Kody OTP i refresh tokeny trzyma proces API w pamięci, nie baza — jeśli chcesz
unieważnić też sesje z testów, zrestartuj go: `docker compose restart api`
(wariant A) albo uvicorna na hoście (wariant B).

### Pełne usunięcie

Poniższe kroki **bezpowrotnie usuwają bazę, wszystkie zdjęcia i wszystkie
dane**. Nie ma kopii zapasowej i nie ma cofnięcia — wolumeny
`backend_pgdata` i `backend_s3data` przestają istnieć. Wykonaj je tylko wtedy,
gdy naprawdę chcesz wrócić do stanu sprzed uruchomienia. Jeśli chodziło Ci
jedynie o zatrzymanie serwera, użyj `docker compose stop` z sekcji powyżej.

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

Zabiera `postgres`, `s3`, `migrate` i `api` razem z siecią `backend_default`.
Flaga `-v` usuwa dodatkowo wolumeny `backend_pgdata` z bazą i `backend_s3data`
ze zdjęciami. Bez niej wolumeny zostają i następne `up -d` wstanie ze starymi
danymi.

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

Pełna, zawsze aktualna lista: `/docs`. Spis z uprawnieniami i tym, czego
jeszcze nie ma: [`stan-obecny.md`](stan-obecny.md#api).

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

Pełna lista z komentarzami: [`../.env.example`](../.env.example). Najważniejsze:

| Zmienna | Domyślnie | Opis |
| ------- | --------- | ---- |
| `DATABASE_URL` | localhost:5432 | połączenie z PostgreSQL |
| `JINA_API_KEY` | – | embeddingi + reranker (wymagane) |
| `GEMINI_API_KEY` | – | rozwijanie zapytań i opisy zdjęć (wymagane) |
| `GEMINI_MODEL` | `gemini-flash-lite-latest` | patrz uwaga niżej |
| `EMBEDDING_PROVIDER` | `jina` | `jina` (1024 wymiary) lub `fastembed` (lokalnie, 384) |
| `MATCH_RERANK_THRESHOLD` | `0.10` | próg dopasowania filtra |
| `OTP_MOCK` | `true` | kod SMS to stałe `123456` |
| `MAX_FILTERS_PER_USER` | `10` | limit filtrów na konto |
| `LISTING_TTL_HOURS` | `72` | `expires_at` nowego ogłoszenia |
| `S3_ENDPOINT` | localhost:4566 | magazyn zdjęć; compose nadpisuje na `s3:4566` |
| `S3_PUBLIC_ENDPOINT` | – | host do podpisywania URL-i; puste znaczy „ten sam co `S3_ENDPOINT`” |
| `S3_PRESIGN_TTL` | `3600` | ile sekund żyje adres zdjęcia |
| `MAX_IMAGES_PER_LISTING` | `6` | limit zdjęć na ogłoszenie |
| `MAX_IMAGE_BYTES` | `10485760` | 10 MB na plik |
| `VISION_ENABLED` | `true` | `false` wyłącza opisy zdjęć, upload działa dalej |

> **`GEMINI_MODEL` i `GEMINI_VISION_MODEL`:** Google wycofuje identyfikatory
> modeli dla nowych kluczy bez zapowiedzi — `gemini-2.5-flash` zwraca już 404.
> Jeśli zobaczysz w logach `query expansion failed` albo
> `vision captioning failed`, wylistuj dostępne modele i podmień wartość:
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

Opisy zdjęć nie mają trybu offline: bez `GEMINI_API_KEY` ustaw
`VISION_ENABLED=false`. Upload, konwersja, usuwanie EXIF i miniatury działają
nadal lokalnie — zdjęcia po prostu przestają wnosić cokolwiek do wyszukiwania.

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
| `api` czeka i nie startuje | `migrate` albo `s3` nie wstał; zobacz `docker compose logs migrate` i `docker compose logs s3` |
| Zmiana w `app/` nie działa w wariancie A | obraz trzyma kopię kodu: `docker compose up -d --build` |
| `License activation failed`, `exit code 55` w logach `s3` | LocalStack na tagu `latest` wymaga licencji; w `docker-compose.yml` ma być `localstack/localstack:4` |
| `vision captioning failed` w logach | nieaktualny `GEMINI_VISION_MODEL` albo zły klucz; zdjęcie się wgra, ale bez opisu |
| Upload zdjęcia zwraca 400 `File is not a readable image` | plik nie jest obrazem albo jest uszkodzony; zadeklarowany `Content-Type` nie wystarcza |
| Upload zdjęcia zwraca 409 | osiągnięty `MAX_IMAGES_PER_LISTING`; usuń jakieś zdjęcie albo podnieś limit |
| Adres zdjęcia zwraca `SignatureDoesNotMatch` | `S3_PUBLIC_ENDPOINT` nie zgadza się z hostem, na który idzie żądanie — podpis obejmuje nagłówek `Host` |
| Adres zdjęcia zwraca `AccessDenied` po czasie | podpis wygasł; weź nowy adres z `GET /listings/{id}` albo podnieś `S3_PRESIGN_TTL` |
| `NoSuchBucket` przy uploadzie | bucket tworzy się przy pierwszym uploadzie; jeśli błąd się powtarza, `s3` nie jest zdrowy: `docker compose ps` |
| Upload trwa kilka sekund | tak ma być: konwersja, dwa zapisy, opis vision, embedding i powtórne dopasowanie w jednym żądaniu |
