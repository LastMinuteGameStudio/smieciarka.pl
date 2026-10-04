"""Seed a local backend with example listings around Warsaw.

Run once on a fresh database, with the API already listening:

    python scripts/seed_listings.py --base-url http://localhost:8000

Each listing is created through POST /listings, so it gets an embedding,
its author's phone and its pickup details like any real listing. Requires
JINA_API_KEY to be set on the backend.
"""

import argparse
import sys
from datetime import date, timedelta

import httpx

OTP_CODE = "123456"

# Demo owners. Their phone numbers are shown on their listings.
OWNERS = ["+48600000101", "+48600000102", "+48600000103"]

# Coordinates are inside the app's default 10 km search radius around Warsaw.
LISTINGS = [
    {
        "title": "Krzesło drewniane",
        "description": "Stare, ale solidne krzesło. Lekko zarysowane z tyłu.",
        "lat": 52.2319,
        "lng": 21.0067,
        "location_label": "Warszawa, Śródmieście",
        "address": "ul. Marszałkowska 10",
    },
    {
        "title": "Stół kuchenny",
        "description": "Stół 120 x 80 cm, do rozłożenia. Odbiór po kontakcie.",
        "lat": 52.2065,
        "lng": 21.0255,
        "location_label": "Warszawa, Mokotów",
        "address": "ul. Puławska 45",
    },
    {
        "title": "Lampa biurkowa",
        "description": "Sprawna, bez uszkodzeń. Kabel w dobrym stanie.",
        "lat": 52.2401,
        "lng": 21.0342,
        "location_label": "Warszawa, Praga",
        "address": None,
    },
    {
        "title": "Rower dziecięcy",
        "description": "Dla dziecka 6–8 lat, w dobrym stanie.",
        "lat": 52.2155,
        "lng": 20.9920,
        "location_label": "Warszawa, Ochota",
        "address": "ul. Grójecka 88",
    },
    {
        "title": "Rękawice bramkarskie",
        "description": "Rozmiar 9, prawie nowe, z zapięciem na rzep.",
        "lat": 52.2480,
        "lng": 21.0010,
        "location_label": "Warszawa, Wola",
        "address": None,
    },
    {
        "title": "Korki rozm. 38",
        "description": "Halowe, użyte kilka razy.",
        "lat": 52.2270,
        "lng": 21.0490,
        "location_label": "Warszawa, Praga-Południe",
        "address": "ul. Grochowska 5",
    },
    {
        "title": "Stolik kawowy",
        "description": "Drewniany, do salonu. Lekkie zarysowania na blacie.",
        "lat": 52.2140,
        "lng": 21.0380,
        "location_label": "Warszawa, Mokotów",
        "address": None,
    },
    {
        "title": "Komoda z szufladami",
        "description": "Trzy szuflady, do przemalowania.",
        "lat": 52.2360,
        "lng": 20.9950,
        "location_label": "Warszawa, Wola",
        "address": "ul. Chłodna 20",
    },
    {
        "title": "Fotel bujany",
        "description": "Wygodny, tapicerka czysta, drobne przetarcia.",
        "lat": 52.2200,
        "lng": 21.0105,
        "location_label": "Warszawa, Ochota",
        "address": None,
    },
    {
        "title": "Deska do prasowania",
        "description": "Z żelazkiem stojakiem, sprawna.",
        "lat": 52.2290,
        "lng": 21.0600,
        "location_label": "Warszawa, Praga-Północ",
        "address": None,
    },
]


def login(client: httpx.Client, phone: str) -> str:
    client.post("/auth/phone/start", json={"phone_number": phone}).raise_for_status()
    response = client.post(
        "/auth/phone/verify",
        json={"phone_number": phone, "code": OTP_CODE},
    )
    response.raise_for_status()
    return response.json()["access_token"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--base-url", default="http://localhost:8000")
    args = parser.parse_args()

    with httpx.Client(base_url=args.base_url, timeout=60) as client:
        tokens = {phone: login(client, phone) for phone in OWNERS}

        created = 0
        for index, listing in enumerate(LISTINGS):
            owner = OWNERS[index % len(OWNERS)]
            pickup = date.today() + timedelta(days=3 + index)
            body = {
                "title": listing["title"],
                "description": listing["description"],
                "location": {"lat": listing["lat"], "lng": listing["lng"]},
                "location_label": listing["location_label"],
                "address": listing["address"],
                "pickup_date": pickup.isoformat(),
            }
            response = client.post(
                "/listings",
                json=body,
                headers={"Authorization": f"Bearer {tokens[owner]}"},
            )
            if response.status_code != 201:
                print(f"FAILED {listing['title']}: {response.status_code} {response.text}")
                return 1
            created += 1
            print(f"created {listing['title']} ({owner})")

    print(f"done: {created} listings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
