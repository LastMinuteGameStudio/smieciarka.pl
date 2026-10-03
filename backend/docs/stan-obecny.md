# Backend – stan obecny

Opis tego, co faktycznie jest w katalogu `backend/` na dzisiaj. Dokument
celowo trzymany osobno od [specyfikacji](../../README.md): specyfikacja mówi,
jak backend ma wyglądać docelowo, ten plik mówi, jak wygląda teraz. Jeśli
widzisz rozbieżność, to prawdę o kodzie ma ten plik, a nie specyfikacja.

Jak to uruchomić: [`uruchomienie.md`](uruchomienie.md).

**Status w jednym zdaniu:** działający prototyp jednego procesu FastAPI nad
jedną bazą PostgreSQL, który realizuje pełną ścieżkę demo — logowanie,
dodanie ogłoszenia, wyszukiwanie semantyczne, filtr nasłuchiwania
i powiadomienie w aplikacji — bez warstwy asynchronicznej, bez zdjęć, bez
pushy i bez prawdziwych SMS-ów.

Rozmiar: około 1100 linii Pythona w `app/`, trzy migracje Alembica, zero
testów.

---

## Spis treści

1. [Co działa od końca do końca](#co-działa-od-końca-do-końca)
2. [Stack faktyczny](#stack-faktyczny)
3. [Architektura](#architektura)
4. [Struktura katalogów](#struktura-katalogów)
5. [Model danych](#model-danych)
6. [Wyszukiwanie](#wyszukiwanie)
7. [Dopasowanie filtrów i powiadomienia](#dopasowanie-filtrów-i-powiadomienia)
8. [Dlaczego klucze są wymagane](#dlaczego-klucze-są-wymagane)
9. [Autoryzacja](#autoryzacja)
10. [API](#api)
11. [Prywatność](#prywatność)
12. [Czego brakuje względem specyfikacji](#czego-brakuje-względem-specyfikacji)
13. [Pierwsze rzeczy do zrobienia](#pierwsze-rzeczy-do-zrobienia)

---

## Co działa od końca do końca

Ścieżka, którą można przejść curl-em i która kończy się powiadomieniem
(komendy: [`uruchomienie.md`](uruchomienie.md#pełny-przepływ-ogłoszenie-wyszukiwanie-powiadomienie)):

1. Logowanie numerem telefonu ze stałym kodem `123456`, z automatyczną
   rejestracją nowego numeru i wydaniem pary tokenów JWT.
2. Dodanie ogłoszenia z tytułem, opcjonalnym opisem i lokalizacją. Embedding
   liczy się w tym samym żądaniu, więc ogłoszenie jest od razu wyszukiwalne.
3. Wyszukiwanie semantyczne bez logowania, opcjonalnie ograniczone promieniem
   od podanego punktu.
4. Utworzenie filtra nasłuchiwania z obszarem `radius` albo `nationwide`.
   Zapytanie filtra jest rozwijane przez LLM i to rozwinięcie jest embedowane.
5. Dopasowanie nowego ogłoszenia do zapisanych filtrów i zapis powiadomień
   w bazie. Powiadomienie odczytuje się przez `GET /notifications` —
   **nie ma wysyłki push**, klient musi odpytywać.

Autor nigdy nie dostaje powiadomienia o własnym ogłoszeniu, więc do testu
dopasowania potrzebne są dwa konta.

---

## Stack faktyczny

| Warstwa | Specyfikacja | Stan obecny |
| ------- | ------------ | ----------- |
| API | Python 3.12 + FastAPI | tak, FastAPI 0.142, obraz na Pythonie 3.13 |
| Baza | PostgreSQL 16 | tak, obraz `pgvector/pgvector:pg16` |
| Wektory | pgvector z indeksem HNSW | pgvector tak, **bez indeksu** (skan sekwencyjny) |
| Geolokalizacja | PostGIS (`ST_DWithin`) | **brak**, odległość liczona wzorem haversine na kolumnach `lat`/`lng` typu `float` |
| Kolejka / cache | Redis | **brak** |
| Workery | Celery | **brak**, wszystko w procesie API |
| Pliki | S3 / MinIO | **brak**, zdjęć nie ma wcale |
| Embeddingi | BGE-M3 / multilingual-e5-large | `jina-embeddings-v3` przez API (1024 wymiary), awaryjnie lokalny `fastembed` (384) |
| Decyzja o dopasowaniu | próg podobieństwa + opcjonalny LLM | `jina-reranker-v2-base-multilingual`, próg na wyniku rerankera |
| Rozwijanie zapytań | LLM | Gemini (`gemini-flash-lite-latest`) przez REST |
| Opis zdjęć | model vision | **brak** |
| Powiadomienia | FCM + Web Push | **brak**, tylko wiersze w tabeli `notifications` |
| SMS / OTP | textbee.dev → SMSAPI.pl | **brak**, tryb `OTP_MOCK` ze stałym kodem |
| ORM / migracje | SQLAlchemy 2.0 + Alembic | tak, SQLAlchemy async z `asyncpg` |
| Infrastruktura | Docker Compose | tak, trzy serwisy: `postgres`, `migrate`, `api` |

Żadna z usług zewnętrznych nie jest self-hostowana: embeddingi, reranker
i rozwijanie zapytań to wywołania HTTP do Jiny i Google.

---

## Architektura

```mermaid
flowchart LR
    Client[Klient] -->|REST + JWT| API[FastAPI<br/>jeden proces]
    API --> PG[(PostgreSQL 16<br/>pgvector)]
    API -->|embeddingi + reranker| Jina[Jina AI API]
    API -->|rozwijanie zapytań filtra| Gemini[Gemini API]
    Client -->|odpytywanie GET /notifications| API
```

Różnica wobec architektury ze specyfikacji jest jedna, ale zasadnicza: **nie ma
workerów**. Embedding ogłoszenia i całe dopasowanie do filtrów wykonują się
synchronicznie w obsłudze `POST /listings`, przed zwróceniem odpowiedzi 201.
Konsekwencje:

- Status techniczny `indexing` nie jest używany — ogłoszenie powstaje od razu
  jako `active`, bo embedding jest już policzony.
- Czas odpowiedzi `POST /listings` zawiera jedno wywołanie embeddingu oraz do
  `MATCH_CANDIDATE_LIMIT` (domyślnie 100) wywołań rerankera, puszczanych po 10
  równolegle. Przy wielu pasujących obszarowo filtrach to sekundy, nie
  milisekundy, a timeout pojedynczego wywołania to 20 s.
- Awaria Jiny nie opóźnia powiadomień, bo nie ma kolejki — rozkłada się na dwa
  różne objawy. Nieudany embedding przerywa `POST /listings` błędem 500
  i ogłoszenie nie powstaje, bo embedding liczy się przed zapisem. Nieudane
  wywołanie rerankera jest łapane i logowane, więc ogłoszenie powstaje
  normalnie, a cicho gubi się tylko powiadomienie dla tego kandydata.
- Ogłoszenie jest commitowane **przed** dopasowaniem, a samo dopasowanie nie
  jest osłonięte `try`. Jeśli padnie z innego powodu niż reranker, klient
  dostaje 500, choć ogłoszenie jest już trwale w bazie. Ponowienie żądania
  utworzy duplikat, więc klient nie powinien powtarzać `POST /listings`
  automatycznie.

Przy skali demo to jest akceptowalne i pozwala pokazać działanie bez
uruchamiania brokera i workerów. Przy jakimkolwiek realnym ruchu trzeba to
wynieść do kolejki, bo cel „push w < 30 s” ze specyfikacji nie ma tu jeszcze
ani kolejki, ani pushy, ani pomiaru.

---

## Struktura katalogów

```
backend/
├── app/
│   ├── main.py                  # FastAPI, montowanie routerów, /health
│   ├── config.py                # pydantic-settings, wszystkie progi i klucze
│   ├── db.py                    # silnik async, sesja, Base
│   ├── api/
│   │   ├── deps.py              # get_current_user, get_optional_user
│   │   ├── auth.py
│   │   ├── listings.py
│   │   ├── filters.py
│   │   └── notifications.py
│   ├── models/                  # User, Listing, WatchFilter, Notification
│   ├── schemas/                 # Pydantic: auth, listing, filter, notification
│   ├── services/
│   │   ├── embeddings.py        # wybór providera: jina albo fastembed
│   │   ├── jina.py              # klient embeddingów i rerankera
│   │   ├── query_expansion.py   # Gemini
│   │   ├── matching.py          # odwrócone wyszukiwanie, dwa etapy
│   │   └── geo.py               # haversine jako wyrażenie SQL
│   └── core/
│       └── security.py          # tokeny JWT, stała MOCK_OTP_CODE
├── migrations/                  # Alembic, trzy wersje
├── docs/
├── alembic.ini
├── docker-compose.yml
├── Dockerfile
├── requirements.txt             # nie pyproject.toml
└── .env.example
```

Względem struktury ze specyfikacji nie ma katalogów `workers/` i `tests/` ani
plików `services/vision.py`, `services/search.py`, `services/storage.py`,
`services/push.py`, `services/sms.py` i `core/rate_limit.py`. Wyszukiwanie nie
ma osobnego serwisu — zapytanie jest zbudowane wprost w `app/api/listings.py`.

---

## Model danych

Cztery tabele. Brakuje `listing_images`, `regions`, `categories`
i `device_tokens`.

```mermaid
erDiagram
    USERS ||--o{ LISTINGS : publikuje
    USERS ||--o{ WATCH_FILTERS : tworzy
    USERS ||--o{ NOTIFICATIONS : otrzymuje
    LISTINGS ||--o{ NOTIFICATIONS : dotyczy
    WATCH_FILTERS ||--o{ NOTIFICATIONS : wyzwala
```

### `users`

Zgodnie ze specyfikacją: `id`, `phone_number` (unikalny), `phone_verified_at`,
`display_name`, `is_banned`, `created_at`. `is_banned` jest sprawdzane przy
autoryzacji, ale nie ma endpointu, który je ustawia.

### `listings`

| Kolumna | Typ | Uwagi |
| ------- | --- | ----- |
| `id` | UUID PK | |
| `author_id` | UUID FK → `users` | |
| `title` | TEXT NOT NULL | maks. 120 znaków (walidacja Pydantic) |
| `description` | TEXT NULL | maks. 2000 znaków |
| `lat`, `lng` | DOUBLE PRECISION | **zamiast** `GEOGRAPHY(Point, 4326)` |
| `location_label` | TEXT NULL | maks. 120 znaków |
| `embedding` | VECTOR(1024) NULL | wymiar z `EMBEDDING_DIM` |
| `status` | ENUM `listing_status` | wartości jak w specyfikacji, w praktyce używane `active`, `reserved`, `given_away` |
| `expires_at` | TIMESTAMPTZ NULL | ustawiane na `now() + LISTING_TTL_HOURS` |
| `created_at` | TIMESTAMPTZ | |

Nie ma `image_caption`, `search_tsv`, `category_ids` ani `region_ids`.
Tekst do embeddingu to `"{title}. {description}"` — bez prefiksów `passage:`
/ `query:`, bo `jina-embeddings-v3` rozróżnia strony parametrem `task`
(`retrieval.passage` dla ogłoszeń, `retrieval.query` dla zapytań i filtrów).

### `watch_filters`

| Kolumna | Typ | Uwagi |
| ------- | --- | ----- |
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `query` | TEXT | to, co wpisał użytkownik, maks. 200 znaków |
| `expanded_query` | TEXT NULL | rozwinięcie z Gemini; `NULL`, gdy się nie udało |
| `embedding` | VECTOR(1024) NULL | liczony z `expanded_query`, awaryjnie z `query` |
| `area_type` | ENUM `area_type` | **tylko `radius` i `nationwide`** |
| `center_lat`, `center_lng` | DOUBLE PRECISION NULL | zamiast `GEOGRAPHY(Point)` |
| `radius_m` | INT NULL | walidacja: 100 – 500 000 m |
| `min_score` | DOUBLE PRECISION NULL | specyfikacja mówi `REAL`; kolumna istnieje, ale **nie jest nigdzie czytana** |
| `is_active` | BOOL | domyślnie `true`, brak endpointu do zmiany |
| `created_at` | TIMESTAMPTZ | |

Nie ma `category_ids` ani `region_ids`. Tryb obszaru `regions` ze specyfikacji
nie istnieje — nie ma go w typie wyliczeniowym, więc żądanie z takim obszarem
odrzuca walidacja.

### `notifications`

Zestaw kolumn jak w specyfikacji: `id`, `user_id`, `listing_id`, `filter_id`,
`score`, `read_at`, `created_at`, z ograniczeniem `UNIQUE(user_id, listing_id)`.
`score` jest typu DOUBLE PRECISION, nie `REAL` — tak jak każda kolumna
zmiennoprzecinkowa w tym schemacie. Wstawka idzie przez
`INSERT ... ON CONFLICT DO NOTHING`, więc przy kilku pasujących filtrach
zapisuje się ten, który trafił pierwszy — nie ten z najwyższym wynikiem.

W `score` siedzi wynik rerankera, czyli nie ta sama skala, co podobieństwo
kosinusowe ze specyfikacji. Wartości są niskie (próg dopasowania to `0.10`)
i nie należy ich pokazywać użytkownikowi jako „procent zgodności".

### Indeksy

**Żadnego z indeksów z sekcji 4 specyfikacji nie ma.** Brak HNSW na
`embedding`, brak GiST, brak GIN. Każde wyszukiwanie i każde dopasowanie
filtrów to pełny skan tabeli z policzeniem odległości kosinusowej dla każdego
wiersza. Warunek promienia też nie korzysta z żadnego indeksu, bo haversine
jest liczony wyrażeniem na kolumnach. Przy kilkudziesięciu ogłoszeniach to bez
znaczenia; przed produkcją indeksy trzeba dodać (patrz
[Pierwsze rzeczy do zrobienia](#pierwsze-rzeczy-do-zrobienia)).

### Migracje

Trzy wersje Alembica, liniowo: `7423f87c964e` (schemat początkowy, wektor 1536
i `CREATE EXTENSION vector`) → `f810b33664ea` (zmiana na 384 pod model lokalny)
→ `8a945c5ffef1` (zmiana na 1024 pod Jinę, `head`).

Tylko ostatnia z nich czyści kolumny `embedding` przed zmianą typu, bo
wektorów z różnych modeli nie da się porównywać. `f810b33664ea` robi samo
`ALTER COLUMN ... TYPE`, co przejdzie tylko wtedy, gdy wszystkie embeddingi są
już `NULL` — na bazie z policzonymi wektorami ta migracja się wysypie na
niezgodności wymiarów. Zadania `reindex_all` nie ma, więc po
zmianie providera embeddingi trzeba policzyć od nowa ręcznie albo wyczyścić
dane.

---

## Wyszukiwanie

`GET /listings/search` jest **wyłącznie wektorowe**. Wyszukiwania hybrydowego
ze specyfikacji (sekcja 5.2) nie ma: nie ma kolumny `search_tsv`, nie ma
`ts_rank` ani łączenia wyników metodą RRF.

Zapytanie: embedding frazy po stronie `retrieval.query`, filtr
`status = 'active'`, sortowanie po odległości kosinusowej, `LIMIT 50`. Jeśli
podano `lat` i `lng`, dochodzi warunek odległości (domyślnie 5000 m) liczonej
haversine'em w SQL. Nie ma progu podobieństwa, więc przy małej liczbie
ogłoszeń w odpowiedzi znajdą się też wyniki słabo pasujące — to świadome, lista
jest posortowana od najlepszego.

Nie ma paginacji kursorem ani sortowania z uwzględnieniem świeżości
i odległości. `GET /listings/nearby` zwraca 50 najnowszych aktywnych ogłoszeń
w promieniu, bez zapytania tekstowego.

Ogłoszenia nie są wygaszane. `expires_at` jest ustawiane przy tworzeniu
i zwracane klientowi w odpowiedzi, ale nic go nie wymusza: nie ma zadania,
które zmienia status na `expired`, ani warunku `expires_at > now()` w żadnym
zapytaniu. Ogłoszenie zostaje `active` i wyszukiwalne bezterminowo, dopóki
autor sam nie zmieni statusu. Do czasu dodania zadania wygaszającego klient
może odfiltrować przeterminowane po tym polu u siebie.

Zapytanie wyszukiwania nie wyklucza ogłoszeń bez embeddingu. Nie ma warunku
`embedding IS NOT NULL`, a `ORDER BY` z wartością `NULL` ustawia takie wiersze
na końcu (`NULLS LAST`), więc trafiają one do odpowiedzi jako najsłabsze
wyniki. W normalnej pracy to nie występuje, bo embedding liczy się przy
tworzeniu ogłoszenia — ale po migracji czyszczącej wektory tak. W dopasowaniu
filtrów problemu nie ma: tam `NULL` nie przechodzi warunku `WHERE`, więc wiersz
wypada.

---

## Dopasowanie filtrów i powiadomienia

Idea odwróconego wyszukiwania jest zrealizowana zgodnie ze specyfikacją: nowe
ogłoszenie jest zapytaniem, a tabela `watch_filters` korpusem. Decyzja jest
jednak dwuetapowa i to jest najważniejsze odstępstwo od specyfikacji — powód
w [następnej sekcji](#dlaczego-klucze-są-wymagane).

**Etap 1, prefiltr w Postgresie** (`app/services/matching.py`). Jedno
zapytanie wybiera filtry, które są aktywne, nie należą do autora ogłoszenia
i pasują obszarem (`nationwide` albo `radius` z warunkiem haversine).
Sortowanie po podobieństwie kosinusowym, `MATCH_CANDIDATE_THRESHOLD` domyślnie
`0.0` i `MATCH_CANDIDATE_LIMIT` domyślnie 100. Próg jest luźny celowo: on tylko
nominuje kandydatów i ogranicza koszt etapu 2, a realnym ograniczeniem jest
limit, nie próg.

**Etap 2, reranker decyduje.** Dla każdego kandydata leci osobne wywołanie
`jina-reranker-v2-base-multilingual`, w którym zapytaniem jest potrzeba
użytkownika (`expanded_query`, awaryjnie `query`), a dokumentem **sam tytuł
ogłoszenia**. Wywołania idą równolegle, maksymalnie 10 naraz. Dopasowaniem jest
wynik ≥ `MATCH_RERANK_THRESHOLD` (domyślnie `0.10`).

Dwie mierzone własności rerankera, które wymuszają taki kształt:

- **Nie jest symetryczny.** Skalibrowany jest tylko kierunek „potrzeba jako
  zapytanie” (separacja `+0.041` kontra `-0.215` w drugą stronę). Dlatego nie
  da się wsadzić wszystkich potrzeb do jednego wywołania wsadowego — każdy
  kandydat to osobne wywołanie.
- **Rozmywa się dodatkowymi tokenami.** `Piłka nożna` dostaje 0.40 dla
  zapytania o piłkę nożną, a `Piłka nożna Adidas, rozmiar 5` tylko 0.06 — mniej
  niż niezwiązany regał na książki. Dlatego dokumentem jest tytuł, nigdy tytuł
  z opisem.

Gdy `JINA_API_KEY` nie jest ustawiony, dopasowanie spada do nieskalibrowanego
kosinusa z progiem `MATCH_THRESHOLD_LOW` (`0.55`) i ostrzeżenia w logach.
Ta ścieżka przepuszcza za dużo, co jest wyborem świadomym: lepiej powiadomić
nadmiarowo niż nie powiadomić nikogo i wyglądać na działające.

W praktyce ścieżka awaryjna jest osiągalna tylko przy
`EMBEDDING_PROVIDER=fastembed`. Przy domyślnym `jina` brak klucza wysadza
wcześniej samo liczenie embeddingu — `POST /listings` kończy się wyjątkiem
z instrukcją, co ustawić, więc dopasowanie w ogóle nie startuje. Jest to
zamierzone: cicha podmiana providera wstawiłaby wektor 384-wymiarowy do
kolumny 1024-wymiarowej i objawiła się nieczytelnym błędem pgvectora.

Weryfikacji strefy szarej przez LLM (specyfikacja 6.3) nie ma — reranker
zastąpił ją w całości. Progi `MATCH_THRESHOLD_LOW` i `MATCH_THRESHOLD_HIGH`
zostały w konfiguracji, ale pierwszy służy już tylko ścieżce awaryjnej, a drugi
nie jest czytany nigdzie.

Z ochrony przed spamem (specyfikacja 6.5) działa deduplikacja przez
`UNIQUE(user_id, listing_id)` i limit filtrów na konto
(`MAX_FILTERS_PER_USER`, domyślnie 10). Nie ma limitu powiadomień na godzinę
ani godzin ciszy — nie ma pushy, więc nie ma czego ograniczać.

Dopasowanie uruchamia się **raz**, przy tworzeniu ogłoszenia. Drugiego
przebiegu po wygenerowaniu opisu zdjęć (specyfikacja 6.6) nie ma, bo nie ma
zdjęć. Edycja ogłoszenia nie istnieje, więc nie ma też przeliczania.

---

## Dlaczego klucze są wymagane

Nieoczywista rzecz, która zdecydowała o architekturze dopasowania, i powód,
dla którego `JINA_API_KEY` i `GEMINI_API_KEY` nie są opcjonalnym ulepszeniem.

Wynik podobieństwa kosinusowego z embeddingów **nie jest skalibrowany**: nie
istnieje stały próg, który oddziela trafienie od nietrafienia. Zmierzone na
zestawie testowym, najgorszy przypadek separacji: `-0.260` dla lokalnego
modelu MiniLM i `-0.007` dla `multilingual-e5-large`, czyli modelu zalecanego
w specyfikacji. Przy pierwotnym progu `0.55` pięć z sześciu ogłoszeń
z przykładu w głównym README nie powiadamiało w ogóle.

Reranker rozwiązuje to, bo jego wyniki są skalibrowane — stały próg `0.10` ma
sens, separacja wynosi `+0.041`. Stąd dwa wymagania, które inaczej wyglądałyby
arbitralnie:

- **Rozwijanie zapytań jest obowiązkowe.** Dla surowego zapytania reranker nie
  rozdziela zbiorów przy żadnym progu (`-0.116`). Dlatego potrzebny jest
  `GEMINI_API_KEY`. Rozwinięcie liczy się raz, przy tworzeniu filtra, i jest
  zapisane w `watch_filters.expanded_query`, więc to kilkanaście wywołań LLM na
  całe demo, nie jedno na ogłoszenie. Próbowano zamiast tego szablonów
  zapytań — wszystkie zawiodły, bo zysk pochodzi z wiedzy o świecie, nie
  z formy zdania.
- **Tryb offline psuje powiadomienia.** Lokalny `fastembed` wystarcza do
  wyszukiwania, bo ono tylko szereguje wyniki. Do powiadomień nie wystarcza,
  bo tam trzeba postawić próg, a żaden próg nie rozdziela tych zbiorów.

Próg `0.10` jest skalibrowany na ręcznie zrobionym zestawie 18 ogłoszeń, nie na
prawdziwych danych.

---

## Autoryzacja

Logowanie numerem telefonu, zgodnie ze specyfikacją jako jedyna metoda, ale
**bez bramki SMS**. Przy `OTP_MOCK=true` (domyślnie) `POST /auth/phone/start`
nic nie wysyła, tylko loguje kod, a jedynym akceptowanym kodem jest stała
`123456` dla dowolnego numeru. Przy `OTP_MOCK=false` endpoint zwraca 501 —
alternatywnej ścieżki nie ma.

Tokeny to JWT podpisane HS256, z polem `type` rozdzielającym `access` od
`refresh`, TTL z `JWT_ACCESS_TTL` (900 s) i `JWT_REFRESH_TTL` (30 dni).
Numer w formacie E.164 i sześciocyfrowy kod wymusza walidacja wzorcem.

Czego nie ma, a jest w specyfikacji w sekcji 7:

- **Stanu OTP nie ma w ogóle** — ani w Redisie, ani w bazie. Nie ma licznika
  prób, więc nie ma czego brute-force'ować dopóki kod jest stały, ale nie ma
  też gdzie trzymać prawdziwego kodu po podłączeniu bramki.
- **`POST /auth/logout` jest pustą zaślepką** i zwraca 204 bez unieważniania
  czegokolwiek. Refresh token działa dalej do końca swojego TTL.
- **Refresh tokeny nie są rotowane ani hashowane w bazie** — nie ma ich w bazie
  wcale, więc nie da się unieważnić sesji.
- **Brak rate limitingu i CAPTCHA**, bo brak Redisa.

To są braki do zamknięcia przed wpuszczeniem prawdziwych numerów, nie przed
demem.

Uprawnienia działają: wyszukiwanie i podglądanie ogłoszeń jest publiczne,
reszta wymaga nagłówka `Authorization: Bearer <access_token>`, a zmiana statusu
ogłoszenia jest sprawdzana pod kątem autorstwa. Konto z `is_banned` nie
przechodzi autoryzacji.

---

## API

Zaimplementowane endpointy. Pełna, generowana lista z ciałami żądań: `/docs`.

| Metoda | Ścieżka | Auth | Uwagi |
| ------ | ------- | ---- | ----- |
| GET | `/health` | – | `{"status":"ok"}`, używane przez healthcheck kontenera |
| POST | `/auth/phone/start` | – | tylko tryb mock, inaczej 501 |
| POST | `/auth/phone/verify` | – | rejestruje nowy numer, zwraca parę tokenów |
| POST | `/auth/refresh` | – | zwraca nową parę, stara zostaje ważna |
| POST | `/auth/logout` | – | zaślepka, 204 bez efektu |
| GET | `/me` | tak | |
| GET | `/listings/search?q=&lat=&lng=&radius=` | opcjonalnie | wektorowo, `LIMIT 50` |
| GET | `/listings/nearby?lat=&lng=&radius=` | opcjonalnie | 50 najnowszych w promieniu |
| GET | `/listings/{id}` | opcjonalnie | zwraca też nieaktywne |
| POST | `/listings` | tak | liczy embedding i odpala dopasowanie |
| POST | `/listings/{id}/status` | autor | tylko `reserved` i `given_away` |
| GET | `/filters` | tak | wszystkie filtry użytkownika |
| POST | `/filters` | tak | rozwija zapytanie, limit `MAX_FILTERS_PER_USER` |
| DELETE | `/filters/{id}` | tak | |
| GET | `/notifications` | tak | 50 najnowszych, bez paginacji |
| POST | `/notifications/{id}/read` | tak | |

„Auth: opcjonalnie” znaczy, że endpoint działa bez tokenu, ale z tokenem autora
zwraca dokładne współrzędne jego własnych ogłoszeń zamiast zaokrąglonych.

Odpowiedź z ogłoszeniem **nie zawiera `author_id`** ani żadnej innej informacji
o autorze. Klient nie ma więc jak odróżnić własnego ogłoszenia od cudzego ani
pokazać, kto oddaje rzecz. Przy ekranie „moje ogłoszenia” albo przyciskach
dostępnych tylko autorowi trzeba będzie dodać to pole do `ListingOut` lub
osobny endpoint — konto autora jest w bazie, tylko nie wychodzi przez API.

Ze specyfikacji nie ma: `PATCH /listings/{id}`, `DELETE /listings/{id}`,
`POST /listings/{id}/images/upload-url`, `POST /listings/{id}/report`,
`PATCH /filters/{id}`, `GET /filters/{id}/preview`, `GET /regions`,
`GET /categories`, `POST /devices`, `DELETE /devices/{token}` oraz endpointów
eksportu i usunięcia konta (RODO).

---

## Prywatność

Dwie rzeczy ze sekcji 12 specyfikacji są zrobione:

- **Numer telefonu** nie wychodzi żadnym publicznym endpointem. `UserOut`
  zwraca go tylko na `GET /me`, czyli właścicielowi konta.
- **Lokalizacja** w odpowiedziach publicznych jest zaokrąglana do trzech miejsc
  po przecinku, czyli siatki około 100 m (`PUBLIC_COORD_DECIMALS`
  w `app/schemas/listing.py`). Dokładny punkt widzi tylko autor ogłoszenia.
  Dotyczy to wszystkich endpointów zwracających ogłoszenia, w tym listy.

Czyszczenia EXIF nie ma, bo nie ma zdjęć. Nie ma endpointów RODO, moderacji ani
wykrywania spamu. Walidacja długości tytułu, opisu, etykiety lokalizacji,
zakresu współrzędnych i promienia jest zrobiona w schematach Pydantic.

---

## Czego brakuje względem specyfikacji

Zbiorczo, dla ustalenia zakresu pracy. Szczegóły w sekcjach powyżej.

**Infrastruktura:** Redis, Celery (embeddingi i dopasowanie liczą się
w żądaniu), MinIO/S3, PostGIS, FCM i Web Push, prawdziwa bramka SMS.

**Tabele:** `listing_images`, `regions`, `categories`, `device_tokens`.
W `listings` brakuje `image_caption`, `search_tsv`, `category_ids`,
`region_ids`; w `watch_filters` brakuje `category_ids` i `region_ids`.

**Indeksy:** żadnego z sekcji 4 — brak HNSW, GiST i GIN.

**Funkcje:** tryb obszaru `regions`, tagowanie kategoriami, weryfikacja strefy
szarej przez LLM, opisy zdjęć modelem vision, wyszukiwanie hybrydowe z RRF,
automatyczne wygaszanie ogłoszeń, paginacja kursorem, limity powiadomień
i godziny ciszy, metryka `notification_latency_seconds`.

**Endpointy:** lista w [sekcji API](#api).

**Bezpieczeństwo:** stan i limit prób OTP, unieważnianie refresh tokenów,
rate limiting, CAPTCHA.

**Testy:** katalogu `tests/` nie ma wcale — ani jednostkowych, ani
integracyjnych, ani zestawu `tests/matching_eval/` do kalibracji progów.
Liczby separacji cytowane w tym dokumencie pochodzą z ręcznych pomiarów na
zestawie 18 ogłoszeń, który nie jest w repozytorium.

---

## Pierwsze rzeczy do zrobienia

Kolejność wynika z tego, co blokuje następne kroki, a nie z wielkości zadania.

1. **Zestaw `tests/matching_eval/`** z parami (ogłoszenie, filtr, pasuje).
   Bez niego każda zmiana w dopasowaniu jest zgadywaniem, a próg `0.10` nie ma
   jak się obronić. To jest też warunek sensownej zmiany modelu embeddingów.
2. **Indeksy HNSW i B-tree** na `(status, created_at)`. Tanie, a usuwa
   niespodziankę wydajnościową przy pierwszym większym zbiorze danych.
3. **Wyniesienie embeddingu i dopasowania do kolejki.** Odcina czas odpowiedzi
   `POST /listings` od awarii i opóźnień Jiny, i daje miejsce na pomiar
   opóźnienia powiadomień.
4. **Wygaszanie ogłoszeń.** `expires_at` jest już zapisywane, brakuje zadania
   i warunku w zapytaniach.
5. **Braki bezpieczeństwa z [sekcji o autoryzacji](#autoryzacja)** — przed
   pierwszym prawdziwym numerem telefonu, razem z podłączeniem bramki SMS.
