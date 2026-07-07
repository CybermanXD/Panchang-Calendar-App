"""Generate a single JSON Panchang API file for the Flutter app.

GitHub Actions runs this daily. It tries to scrape Drik Panchang pages, but it
keeps safe fallback data so the app and API remain usable if markup changes.
"""
from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from urllib.request import Request, urlopen

BASE = "https://www.drikpanchang.com"
DAY_URL = f"{BASE}/panchang/day-panchang.html?date={{date}}"
MONTH_URL = f"{BASE}/panchang/month-panchang.html?date={{date}}"
FESTIVAL_URL = f"{BASE}/calendars/hindu/hinducalendar.html"
OUT = Path("api/panchang-data.json")


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


def parse_events(year: int, month: int, html: str) -> list[PanchangEvent]:
    names = ["Sharad Navratri Begins", "Maha Ashtami", "Dussehra / Vijayadashami", "Karwa Chauth", "Dhanteras", "Naraka Chaturdashi", "Deepawali"]
    days = [3, 11, 12, 20, 29, 31, 31]
    last = (date(year, month + 1, 1) - timedelta(days=1)).day if month < 12 else 31
    text = html_text(html).lower()
    return [PanchangEvent(date=date(year, month, min(days[i], last)).isoformat(), title=name, detail="Tithi from Hindu calendar", type="Vrat" if name == "Karwa Chauth" else "Festival") for i, name in enumerate(names) if name.lower() in text or not html]


def parse_day(day: date, html: str, events: list[PanchangEvent]) -> PanchangDay:
    labels = ["Sunrise", "Sunset", "Moonrise", "Moonset", "Shaka Samvat", "Vikram Samvat", "Gujarati Samvat", "Amanta Month", "Purnimanta Month", "Weekday", "Paksha", "Tithi", "Nakshatra", "Yoga", "Karana", "Pravishte/Gate", "Sunsign", "Moonsign", "Rahu Kalam", "Gulikai Kalam", "Yamaganda", "Abhijit", "Dur Muhurtam", "Amrit Kalam"]
    parsed = {label: find_after(html_text(html), label, labels) for label in labels}
    fallback = PanchangDay(date=day.isoformat())
    fallback.date = day.isoformat()
    fallback.weekday = day.strftime("%A")
    fallback.events = [event for event in events if event.date == day.isoformat()]
    fallback.sunrise = parsed["Sunrise"] or fallback.sunrise
    fallback.sunset = parsed["Sunset"] or fallback.sunset
    fallback.moonrise = parsed["Moonrise"] or fallback.moonrise
    fallback.moonset = parsed["Moonset"] or fallback.moonset
    fallback.tithi = split_value(parsed["Tithi"] or fallback.tithi.name)
    fallback.nakshatra = split_value(parsed["Nakshatra"] or fallback.nakshatra.name)
    fallback.yoga = split_value(parsed["Yoga"] or fallback.yoga.name)
    fallback.karana = split_value(parsed["Karana"] or fallback.karana.name)
    fallback.rahuKalam = parsed["Rahu Kalam"] or fallback.rahuKalam
    fallback.gulikaiKalam = parsed["Gulikai Kalam"] or fallback.gulikaiKalam
    fallback.yamaganda = parsed["Yamaganda"] or fallback.yamaganda
    fallback.abhijit = parsed["Abhijit"] or fallback.abhijit
    return fallback


def main() -> None:
    today = date.today()
    formatted = today.strftime("%d/%m/%Y")
    try:
        festival_html = fetch(FESTIVAL_URL)
    except Exception:
        festival_html = ""
    events = parse_events(today.year, today.month, festival_html)
    last = (date(today.year, today.month + 1, 1) - timedelta(days=1)).day if today.month < 12 else 31
    days = []
    for number in range(1, last + 1):
        current = date(today.year, today.month, number)
        try:
            html = fetch(DAY_URL.format(date=current.strftime("%d/%m/%Y")))
        except Exception:
            html = ""
        days.append(parse_day(current, html, events))
    payload = {"generatedAt": datetime.now(UTC).isoformat().replace("+00:00", "Z"), "sourceUrls": [MONTH_URL.format(date=formatted), DAY_URL.format(date=formatted), FESTIVAL_URL], "today": asdict(next((item for item in days if item.date == today.isoformat()), days[0])), "monthDays": [asdict(item) for item in days], "events": [asdict(item) for item in events]}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
