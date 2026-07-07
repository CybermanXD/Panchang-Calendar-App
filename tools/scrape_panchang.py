"""Generate a single JSON Panchang API file for the Flutter app.

GitHub Actions runs this daily. It tries to scrape Drik Panchang pages, but it
keeps safe fallback data so the app and API remain usable if markup changes.
"""
from __future__ import annotations

import json
import os
import re
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from urllib.request import Request, urlopen

BASE = "https://www.drikpanchang.com"
DAY_URL = f"{BASE}/panchang/day-panchang.html?date={{date}}"
MONTH_URL = f"{BASE}/panchang/month-panchang.html?date={{date}}"
FESTIVAL_URL = f"{BASE}/calendars/hindu/hinducalendar.html"
OUT = Path("api/panchang-data.json")
MAX_WORKERS = int(os.environ.get("PANCHANG_SCRAPE_WORKERS", "8"))


@dataclass
class PanchangValue:
    name: str
    detail: str = ""


@dataclass
class PanchangEvent:
    date: str
    title: str
    detail: str
    type: str = "Festival"


@dataclass
class PanchangDay:
    date: str
    sunrise: str = "06:24 AM"
    sunset: str = "05:58 PM"
    moonrise: str = "12:30 AM"
    moonset: str = "01:11 PM"
    shakaSamvat: str = "1948 Parabhava"
    vikramSamvat: str = "2083 Siddharthi"
    gujaratiSamvat: str = "2082 Pingala"
    amantaMonth: str = "Ashwin"
    purnimantaMonth: str = "Kartika"
    weekday: str = "Budhawara"
    paksha: str = "Shukla Paksha"
    tithi: PanchangValue = field(default_factory=lambda: PanchangValue("Dashami", "Ends 03:14 PM"))
    nakshatra: PanchangValue = field(default_factory=lambda: PanchangValue("Dhanishta", "Till 05:42 PM"))
    yoga: PanchangValue = field(default_factory=lambda: PanchangValue("Vriddhi", "Till 02:30 AM"))
    karana: PanchangValue = field(default_factory=lambda: PanchangValue("Gara", "Till 03:14 PM"))
    pravishte: str = "24"
    sunsign: str = "Mithuna"
    moonsign: str = "Meena upto 04:00 PM"
    rahuKalam: str = "03:04 PM - 04:31 PM"
    gulikaiKalam: str = "12:11 PM - 01:38 PM"
    yamaganda: str = "07:16 AM - 09:02 AM"
    abhijit: str = "11:43 AM - 12:28 PM"
    durMuhurtam: str = "12:07 PM - 01:04 PM"
    amritKalam: str = "01:38 PM - 03:13 PM"
    events: list[PanchangEvent] = field(default_factory=list)


def fetch(url: str) -> str:
    request = Request(url, headers={"User-Agent": "Mozilla/5.0 PanchangCalendarBot/0.1"})
    with urlopen(request, timeout=25) as response:
        return response.read().decode("utf-8", errors="ignore")


def html_text(html: str) -> str:
    text = re.sub(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", " ", html, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text.replace("&nbsp;", " ").replace("&amp;", "&")).strip()


def find_after(text: str, label: str, labels: list[str]) -> str | None:
    stops = "|".join(re.escape(item) for item in labels if item != label)
    match = re.search(rf"{re.escape(label)}\s*(.*?)(?={stops}|$)", text, flags=re.I)
    return match.group(1).strip(" :-")[:80].strip() if match else None


def split_value(value: str) -> PanchangValue:
    match = re.match(r"(.+?)\s+(upto|till|ends?)\s+(.+)", value, flags=re.I)
    return PanchangValue(match.group(1).strip(), f"{match.group(2).title()} {match.group(3).strip()}") if match else PanchangValue(value, "")


TIME_PATTERN = re.compile(r"\b\d{1,2}:\d{2}\s*(?:AM|PM)\b", re.I)
TIME_RANGE_PATTERN = re.compile(r"\b\d{1,2}:\d{2}\s*(?:AM|PM)\s*(?:-|to)\s*\d{1,2}:\d{2}\s*(?:AM|PM)\b", re.I)
DIRTY_WORDS = ("calendar", "panchang", "muhurat", "dates", "sign in", "download", "settings", "festival")


def clean_time(value: str | None, fallback: str) -> str:
    if not value:
        return fallback
    match = TIME_PATTERN.search(value)
    return match.group(0).upper().replace("  ", " ") if match else fallback


def clean_range(value: str | None, fallback: str) -> str:
    if not value:
        return fallback
    match = TIME_RANGE_PATTERN.search(value)
    return re.sub(r"\s+to\s+", " - ", match.group(0), flags=re.I).upper() if match else fallback


def clean_text(value: str | None, fallback: str, max_words: int = 4) -> str:
    if not value:
        return fallback
    cleaned = re.sub(r"\s+", " ", value).strip(" :-,.")
    lower = cleaned.lower()
    if len(cleaned) > 48 or any(word in lower for word in DIRTY_WORDS):
        return fallback
    words = cleaned.split()
    return " ".join(words[:max_words]) if words else fallback


FALLBACK_EVENTS_BY_YEAR = {
    2026: [
        (10, 3, "Sharad Navratri Begins", "Pratipada Tithi", "Festival"),
        (10, 11, "Maha Ashtami", "Ashtami Tithi", "Vrat"),
        (10, 12, "Dussehra / Vijayadashami", "Dashami Tithi", "Festival"),
        (10, 20, "Karwa Chauth", "Chaturthi Tithi", "Vrat"),
        (10, 29, "Dhanteras", "Trayodashi Tithi", "Festival"),
        (10, 31, "Naraka Chaturdashi", "Chaturdashi Tithi", "Festival"),
        (10, 31, "Deepawali", "Kartik Amavasya", "Festival"),
    ],
}


def fallback_events_for_year(year: int) -> list[PanchangEvent]:
    return [
        PanchangEvent(date=date(year, month, day).isoformat(), title=title, detail=detail, type=event_type)
        for month, day, title, detail, event_type in FALLBACK_EVENTS_BY_YEAR.get(year, [])
    ]


def parse_events_for_year(year: int, html: str) -> list[PanchangEvent]:
    # Do not stamp a globally found festival name into every month. Until the
    # Drik yearly table parser is strict enough, keep fallback events as real
    # one-off date records so months without events stay empty.
    return fallback_events_for_year(year)


def parse_day(day: date, html: str, events: list[PanchangEvent]) -> PanchangDay:
    labels = ["Sunrise", "Sunset", "Moonrise", "Moonset", "Shaka Samvat", "Vikram Samvat", "Gujarati Samvat", "Amanta Month", "Purnimanta Month", "Weekday", "Paksha", "Tithi", "Nakshatra", "Yoga", "Karana", "Pravishte/Gate", "Sunsign", "Moonsign", "Rahu Kalam", "Gulikai Kalam", "Yamaganda", "Abhijit", "Dur Muhurtam", "Amrit Kalam"]
    parsed = {label: find_after(html_text(html), label, labels) for label in labels}
    fallback = PanchangDay(date=day.isoformat())
    fallback.date = day.isoformat()
    fallback.weekday = day.strftime("%A")
    fallback.events = [event for event in events if event.date == day.isoformat()]
    fallback.sunrise = clean_time(parsed["Sunrise"], fallback.sunrise)
    fallback.sunset = clean_time(parsed["Sunset"], fallback.sunset)
    fallback.moonrise = clean_time(parsed["Moonrise"], fallback.moonrise)
    fallback.moonset = clean_time(parsed["Moonset"], fallback.moonset)
    fallback.shakaSamvat = clean_text(parsed["Shaka Samvat"], fallback.shakaSamvat)
    fallback.vikramSamvat = clean_text(parsed["Vikram Samvat"], fallback.vikramSamvat)
    fallback.gujaratiSamvat = clean_text(parsed["Gujarati Samvat"], fallback.gujaratiSamvat)
    fallback.amantaMonth = clean_text(parsed["Amanta Month"], fallback.amantaMonth, max_words=2)
    fallback.purnimantaMonth = clean_text(parsed["Purnimanta Month"], fallback.purnimantaMonth, max_words=2)
    fallback.paksha = clean_text(parsed["Paksha"], fallback.paksha, max_words=3)
    fallback.tithi = split_value(clean_text(parsed["Tithi"], fallback.tithi.name))
    fallback.nakshatra = split_value(clean_text(parsed["Nakshatra"], fallback.nakshatra.name))
    fallback.yoga = split_value(clean_text(parsed["Yoga"], fallback.yoga.name))
    fallback.karana = split_value(clean_text(parsed["Karana"], fallback.karana.name))
    fallback.rahuKalam = clean_range(parsed["Rahu Kalam"], fallback.rahuKalam)
    fallback.gulikaiKalam = clean_range(parsed["Gulikai Kalam"], fallback.gulikaiKalam)
    fallback.yamaganda = clean_range(parsed["Yamaganda"], fallback.yamaganda)
    fallback.abhijit = clean_range(parsed["Abhijit"], fallback.abhijit)
    fallback.durMuhurtam = clean_range(parsed["Dur Muhurtam"], fallback.durMuhurtam)
    fallback.amritKalam = clean_range(parsed["Amrit Kalam"], fallback.amritKalam)
    return fallback


def main() -> None:
    today = date.today()
    formatted = today.strftime("%d/%m/%Y")
    try:
        festival_html = fetch(FESTIVAL_URL)
    except Exception:
        festival_html = ""
    events = parse_events_for_year(today.year, festival_html)
    year_days = [date(today.year, 1, 1) + timedelta(days=offset) for offset in range(366 if today.year % 4 == 0 else 365) if (date(today.year, 1, 1) + timedelta(days=offset)).year == today.year]

    def fetch_day(current: date) -> PanchangDay:
        try:
            html = fetch(DAY_URL.format(date=current.strftime("%d/%m/%Y")))
        except Exception:
            html = ""
        return parse_day(current, html, events)

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        days = list(executor.map(fetch_day, year_days))
    payload = {"generatedAt": datetime.now(UTC).isoformat().replace("+00:00", "Z"), "sourceUrls": [MONTH_URL.format(date=formatted), DAY_URL.format(date=formatted), FESTIVAL_URL], "today": asdict(next((item for item in days if item.date == today.isoformat()), days[0])), "monthDays": [asdict(item) for item in days], "events": [asdict(item) for item in events]}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
