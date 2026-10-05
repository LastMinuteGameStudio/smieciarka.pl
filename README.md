# UczciwaCena

Aplikacja mobilna, która pomaga znaleźć darmowe przedmioty wystawione przy altanach śmietnikowych — zanim trafią na wysypisko.

## Problem

Na grupach typu "Uwaga! Śmieciarka jedzie" pojawia się ogromny wolumen treści informacyjnych o dobrach pozostawionych przy altanach śmietnikowych — w dużych miastach nawet post co 2 minuty. Ręczne przeglądanie takich grup jest czasochłonne, a wartościowe lub poszukiwane przedmioty trafiają na wysypisko albo znikają, zanim zainteresowani zdążą zobaczyć post lub na niego zareagować.

Naszą misją jest wsparcie użytkowników tych grup w poszukiwaniu przedmiotów poprzez precyzyjne filtrowanie oraz powiadomienia o pojawieniu się poszukiwanego przedmiotu w okolicy. Eliminując szum informacyjny, zwiększamy szansę na drugie życie wielu przedmiotów i wzmacniamy ekosystem zero-waste oraz recyklingu. Faworyzujemy zachowania proekologiczne, darmową wymianę i działania lokalne nad komercyjną sprzedażą. Razem ograniczmy marnotrawstwo zasobów!

## Rozwiązanie

UczciwaCena to aplikacja służąca do wystawiania darmowych ofert i powiadamiania użytkowników o tych dostępnych w ich okolicy.

- **Własne filtry** — użytkownik definiuje kryteria, na podstawie których otrzymuje powiadomienia push.
- **Wyszukiwanie semantyczne** — np. zapytanie "rzeczy do piłki nożnej" zwróci zarówno piłki, jak i rękawice bramkarskie.
- **Przeglądanie ofert** — bieżąca lista aktualnych ogłoszeń w okolicy, dostępna także bez logowania.

Celem jest promowanie recyklingu, zmniejszanie liczby przedmiotów lądujących na wysypiskach oraz wydłużanie ich okresu użyteczności.

## Status projektu

Działa prototyp obejmujący aplikację mobilną oraz backend, prezentujący podstawowe funkcjonalności, w tym wyszukiwanie semantyczne lokalnych ofert. Backend jest hostowany online, więc funkcje aplikacji można przetestować na żywo.

**Cel docelowy:** stabilna wersja aplikacji z pełną funkcjonalnością, wydana na Google Play oraz App Store — aby usprawnić oddawanie przedmiotów za darmo i ułatwić ich wyszukiwanie, zwiększając popularność działań zero-waste.

## Repozytorium

https://github.com/LastMinuteGameStudio/smieciarka.pl/

## Jak uruchomić projekt (demo)

1. Pobierz plik APK: [app-arm64-v8a-debug.apk](https://github.com/LastMinuteGameStudio/smieciarka.pl/releases/tag/v0.1.0-demo)
2. Zainstaluj: na Androidzie otwórz pobrany plik i zezwól na instalację z tego źródła.
3. Uruchom aplikację **UczciwaCena**. Nie trzeba niczego konfigurować.
4. Przeglądaj ogłoszenia bez logowania. Na liście działa filtr odległości, w tym opcja „Cała Polska”.
5. Logowanie (wymagane do alertów, dodawania ogłoszeń i profilu): wpisz numer telefonu bez prefiksu +48 (9 cyfr) — kod SMS to zawsze `123456`.
