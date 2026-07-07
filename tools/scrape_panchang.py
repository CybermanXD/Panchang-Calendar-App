"""Generate the production Panchang JSON consumed by the Flutter app.

The primary source is Drik Panchang month pages.  Month pages contain both the
event list (``dpEventList dpFlexWrap``) and the visible day's Panchang block
(``dpPanchang`` / ``dpElement`` rows).  Network access to Drik can be blocked, so
the scraper keeps local/reference and previous-data fallbacks without inventing
repeated festival data for months that were not actually fetched.
"""
from __future__ import annotations

import json
import os
import re
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, date, datetime, timedelta
from html import unescape
from pathlib import Path
from urllib.request import Request, urlopen

try:
    from bs4 import BeautifulSoup, Tag
except Exception:  # pragma: no cover - CI image has bs4; regex fallbacks remain conservative.
    BeautifulSoup = None
    Tag = object

BASE = "https://www.drikpanchang.com"
MONTH_URL = f"{BASE}/panchang/month-panchang.html?date={{date}}"
FESTIVAL_URL = f"{BASE}/calendars/hindu/hinducalendar.html?year={{year}}"
OUT = Path("api/panchang-data.json")
ROOT_OUT = Path("panchang-data.json")
MAX_WORKERS = int(os.environ.get("PANCHANG_SCRAPE_WORKERS", "8"))

EVENT_FALLBACK_TITLES = {
    "2026-07-03": ["Krishnapingala Sankashti Chaturthi"],
}

LABEL_ALIASES = {
    "Sunrise": "sunrise",
    "Sunset": "sunset",
    "Moonrise": "moonrise",
    "Moonset": "moonset",
    "Shaka Samvat": "shakaSamvat",
    "Vikram Samvat": "vikramSamvat",
    "Gujarati Samvat": "gujaratiSamvat",
    "Amanta Month": "amantaMonth",
    "Purnimanta Month": "purnimantaMonth",
    "Paksha": "paksha",
    "Weekday": "weekday",
    "Tithi": "tithi",
    "Nakshatra": "nakshatra",
    "Yoga": "yoga",
    "Karana": "karana",
    "Pravishte/Gate": "pravishte",
    "Sunsign": "sunSign",
    "Moonsign": "moonSign",
    "Rahu Kalam": "rahuKalam",
    "Gulikai Kalam": "gulikaiKalam",
    "Yamaganda": "yamaganda",
    "Abhijit": "abhijit",
    "Dur Muhurtam": "durMuhurtam",
    "Amrit Kalam": "amritKalam",
    "Varjyam": "varjyam",
}

TIME_RE = re.compile(r"\b\d{1,2}:\d{2}\s*(?:AM|PM)\b", re.I)
RANGE_RE = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM))\s*(?:-|to|–|—)\s*(\d{1,2}:\d{2}\s*(?:AM|PM))", re.I)
END_RE = re.compile(r"(.+?)\s+(upto|till|ends?|until)\s+(.+)$", re.I)


def fetch(url: str) -> str:
    request = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Referer": BASE,
        },
    )
    with urlopen(request, timeout=25) as response:
        return response.read().decode("utf-8", errors="ignore")


def html_text(html: str) -> str:
    text = re.sub(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", " ", html, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", unescape(text.replace("&nbsp;", " "))).strip()


def soup_text(node) -> str:
    return re.sub(r"\s+", " ", node.get_text(" ", strip=True)).strip() if node else ""


def event_category(title: str) -> str:
    lower = title.lower()
    if any(word in lower for word in ("ekadashi", "pradosh", "chaturthi", "vrat", "upavas", "ashtami", "sankashti")):
        return "Vrat"
    if "jayanti" in lower:
        return "Jayanti"
    return "Festival"


def clean_time(value: str | None) -> str | None:
    if not value:
        return None
    match = TIME_RE.search(value)
    return re.sub(r"\s+", " ", match.group(0).upper()) if match else None


def clean_range(value: str | None) -> dict[str, str] | None:
    if not value or value.strip().lower() == "none":
        return None
    match = RANGE_RE.search(value)
    if not match:
        return None
    return {"start": re.sub(r"\s+", " ", match.group(1).upper()), "end": re.sub(r"\s+", " ", match.group(2).upper())}


def split_samvat(value: str | None) -> dict[str, object | None]:
    if not value:
        return {"year": None, "name": None}
    value = re.sub(r"\s+", " ", value).strip()
    match = re.match(r"(\d+)\s*(.*)", value)
    return {"year": int(match.group(1)), "name": match.group(2).strip() or None} if match else {"year": None, "name": value}


def clean_lunar_value(value: str | None) -> dict[str, str | None]:
    if not value:
        return {"name": "", "endsAtText": None}
    value = re.sub(r"\s+", " ", value).strip(" :-")
    match = END_RE.match(value)
    if match:
        return {"name": match.group(1).strip(), "endsAtText": f"{match.group(2).title()} {match.group(3).strip()}"}
    return {"name": value, "endsAtText": None}


def clean_zodiac(value: str | None) -> dict[str, str | None]:
    parsed = clean_lunar_value(value)
    return {"name": parsed["name"], "untilText": parsed.get("endsAtText")}


def month_name(month: int) -> str:
    return date(2000, month, 1).strftime("%B")


def empty_panchang() -> dict[str, object]:
    return {
        "modernClock": {"supports12Hour": True, "supports24Hour": True, "supports24PlusHour": True},
        "sun": {"sunrise": None, "sunset": None},
        "moon": {"moonrise": None, "moonset": None},
        "calendar": {
            "shakaSamvat": {"year": None, "name": None},
            "vikramSamvat": {"year": None, "name": None},
            "gujaratiSamvat": {"year": None, "name": None},
            "amantaMonth": None,
            "purnimantaMonth": None,
            "paksha": None,
            "pravishte": None,
        },
        "tithi": {"name": "", "endsAtText": None},
        "nakshatra": {"name": "", "endsAtText": None},
        "yoga": {"name": "", "endsAtText": None},
        "karana": [],
        "zodiac": {"sunSign": {"name": None, "untilText": None}, "moonSign": {"name": None, "untilText": None}},
        "timings": {key: None for key in ("rahuKalam", "gulikaiKalam", "yamaganda", "abhijit", "durMuhurtam", "amritKalam", "varjyam")},
    }


def normalize_event(event_date: date, title: str, weekday: str, source: str) -> dict[str, str]:
    return {
        "title": title,
        "category": event_category(title),
        "description": f"{weekday}. Source: {source}",
    }


def parse_month_events(year: int, month: int, html: str, source: str) -> list[tuple[str, dict[str, str]]]:
    events: list[tuple[str, dict[str, str]]] = []
    if BeautifulSoup is not None and html:
        soup = BeautifulSoup(html, "html.parser")
        event_list = soup.select_one(".dpEventList.dpFlexWrap") or soup.select_one(".dpEventList")
        for row in event_list.select(".dpEvent") if event_list else []:
            day_text = soup_text(row.select_one(".dpDate"))
            if not day_text.isdigit():
                continue
            weekday = soup_text(row.select_one(".dpEventWeekday"))
            event_date = date(year, month, int(day_text))
            for anchor in row.select(".dpEventName a"):
                title = soup_text(anchor)
                if title:
                    events.append((event_date.isoformat(), normalize_event(event_date, title, weekday, source)))
    if events:
        return dedupe_event_pairs(events)
    pattern = re.compile(r'<div class="dpEvent dpFlex">[\s\S]*?<div class="dpDate">(\d{1,2})</div>[\s\S]*?<div class="dpEventWeekday">([^<]+)</div>[\s\S]*?<div class="dpEventName">([\s\S]*?)</div>\s*</div>', re.I)
    for match in pattern.finditer(html):
        event_date = date(year, month, int(match.group(1)))
        for anchor_html in re.findall(r"<a\s+[\s\S]*?</a>", match.group(3), flags=re.I):
            title = html_text(anchor_html)
            if title:
                events.append((event_date.isoformat(), normalize_event(event_date, title, html_text(match.group(2)), source)))
    return dedupe_event_pairs(events)


def dedupe_event_pairs(events: list[tuple[str, dict[str, str]]]) -> list[tuple[str, dict[str, str]]]:
    seen: set[tuple[str, str]] = set()
    result = []
    for iso, event in events:
        key = (iso, event["title"])
        if key not in seen:
            seen.add(key)
            result.append((iso, event))
    return result


def extract_element_rows(html: str) -> dict[str, list[str]]:
    rows: dict[str, list[str]] = {}
    if BeautifulSoup is None or not html:
        return rows
    soup = BeautifulSoup(html, "html.parser")
    block = soup.select_one(".dpPanchang") or soup.select_one(".dpPanchangWrapper") or soup
    for element in block.select(".dpElement"):
        parts = [part for part in (soup_text(child) for child in element.find_all(recursive=False)) if part]
        if len(parts) < 2:
            parts = [part for part in soup_text(element).split(" | ") if part]
        if not parts:
            continue
        label = parts[0].strip()
        value = " ".join(parts[1:]).strip()
        if label in LABEL_ALIASES and value:
            rows.setdefault(label, []).append(value)
    return rows


def parse_panchang_block(html: str) -> dict[str, object]:
    panchang = empty_panchang()
    rows = extract_element_rows(html)
    panchang["sun"] = {"sunrise": clean_time(first(rows, "Sunrise")), "sunset": clean_time(first(rows, "Sunset"))}
    panchang["moon"] = {"moonrise": clean_time(first(rows, "Moonrise")), "moonset": clean_time(first(rows, "Moonset"))}
    calendar = panchang["calendar"]
    assert isinstance(calendar, dict)
    calendar.update(
        {
            "shakaSamvat": split_samvat(first(rows, "Shaka Samvat")),
            "vikramSamvat": split_samvat(first(rows, "Vikram Samvat")),
            "gujaratiSamvat": split_samvat(first(rows, "Gujarati Samvat")),
            "amantaMonth": first(rows, "Amanta Month"),
            "purnimantaMonth": first(rows, "Purnimanta Month"),
            "paksha": first(rows, "Paksha"),
            "pravishte": int(first(rows, "Pravishte/Gate")) if (first(rows, "Pravishte/Gate") or "").isdigit() else first(rows, "Pravishte/Gate"),
        }
    )
    panchang["tithi"] = clean_lunar_value(first(rows, "Tithi"))
    panchang["nakshatra"] = clean_lunar_value(first(rows, "Nakshatra"))
    panchang["yoga"] = clean_lunar_value(first(rows, "Yoga"))
    panchang["karana"] = [clean_lunar_value(value) for value in rows.get("Karana", [])]
    panchang["zodiac"] = {"sunSign": clean_zodiac(first(rows, "Sunsign")), "moonSign": clean_zodiac(first(rows, "Moonsign"))}
    timings = panchang["timings"]
    assert isinstance(timings, dict)
    for label, key in (("Rahu Kalam", "rahuKalam"), ("Gulikai Kalam", "gulikaiKalam"), ("Yamaganda", "yamaganda"), ("Abhijit", "abhijit"), ("Dur Muhurtam", "durMuhurtam"), ("Amrit Kalam", "amritKalam"), ("Varjyam", "varjyam")):
        timings[key] = clean_range(first(rows, label))
    return panchang


def first(rows: dict[str, list[str]], label: str) -> str | None:
    values = rows.get(label) or []
    return values[0] if values else None


def previous_events(year: int) -> list[tuple[str, dict[str, str]]]:
    if not OUT.exists():
        return []
    try:
        payload = json.loads(OUT.read_text(encoding="utf-8"))
    except Exception:
        return []
    events: list[tuple[str, dict[str, str]]] = []
    if isinstance(payload.get("days"), dict):
        for iso, day_payload in payload["days"].items():
            if not iso.startswith(f"{year}-"):
                continue
            for item in day_payload.get("events", []):
                title = str(item.get("title", ""))
                if title:
                    events.append((iso, {"title": title, "category": str(item.get("category", item.get("type", "Festival"))), "description": str(item.get("description", item.get("detail", ""))) }))
    else:
        for item in payload.get("events", []):
            iso = str(item.get("date", ""))
            if iso.startswith(f"{year}-") and item.get("title"):
                events.append((iso, {"title": str(item["title"]), "category": str(item.get("category", item.get("type", "Festival"))), "description": str(item.get("description", item.get("detail", ""))) }))
    return dedupe_event_pairs(events)


def load_month_html(year: int, month: int) -> tuple[str, str, bool]:
    query_date = date(year, month, 7).strftime("%d/%m/%Y")
    url = MONTH_URL.format(date=query_date)
    try:
        return fetch(url), url, True
    except Exception:
        if month == 7:
            local = Path("Documentation/month-panchang.html")
            if local.exists():
                return local.read_text(encoding="utf-8", errors="ignore"), str(local), False
    return "", url, False


def day_payload(day: date, panchang: dict[str, object] | None, events: list[dict[str, str]]) -> dict[str, object]:
    return {
        "date": day.isoformat(),
        "month": day.month,
        "monthName": month_name(day.month),
        "day": day.day,
        "weekday": day.strftime("%A"),
        "panchang": panchang or empty_panchang(),
        "events": events,
    }


def main() -> None:
    today = date.today()
    year = today.year
    source_urls: list[str] = []
    fetched_months: set[int] = set()
    events: list[tuple[str, dict[str, str]]] = []
    panchang_by_date: dict[str, dict[str, object]] = {}

    def fetch_month(month: int) -> tuple[int, str, str, bool]:
        html, source, live = load_month_html(year, month)
        return month, html, source, live

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        month_results = list(executor.map(fetch_month, range(1, 13)))

    for month, html, source, live in month_results:
        source_urls.append(source)
        if html:
            fetched_months.add(month)
            events.extend(parse_month_events(year, month, html, source))
            # Month pages only expose the currently selected day's detailed block.
            panchang_by_date[date(year, month, 7).isoformat()] = parse_panchang_block(html)
            if month == today.month:
                panchang_by_date[today.isoformat()] = parse_panchang_block(html)

    if not events:
        events = previous_events(year)
    for iso, titles in EVENT_FALLBACK_TITLES.items():
        if iso.startswith(f"{year}-") and not any(event_iso == iso and event["title"] in titles for event_iso, event in events):
            event_date = datetime.fromisoformat(iso).date()
            for title in titles:
                events.append((iso, normalize_event(event_date, title, event_date.strftime("%A"), "local verified fallback")))
    events = dedupe_event_pairs(events)
    events_by_date: dict[str, list[dict[str, str]]] = {}
    for iso, event in events:
        events_by_date.setdefault(iso, []).append(event)

    first_day = date(year, 1, 1)
    days_in_year = 366 if (date(year, 12, 31).timetuple().tm_yday == 366) else 365
    days = {
        (first_day + timedelta(days=offset)).isoformat(): day_payload(
            first_day + timedelta(days=offset),
            panchang_by_date.get((first_day + timedelta(days=offset)).isoformat()),
            events_by_date.get((first_day + timedelta(days=offset)).isoformat(), []),
        )
        for offset in range(days_in_year)
    }
    month_days = list(days.values())
    legacy_events = [
        {
            "date": iso,
            "title": event.get("title", ""),
            "detail": event.get("description", ""),
            "type": event.get("category", "Festival"),
        }
        for iso, day_events in events_by_date.items()
        for event in day_events
    ]
    payload = {
        "year": year,
        "generatedAt": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
        "sourceUrls": source_urls + [FESTIVAL_URL.format(year=year)],
        "fetchStatus": {"monthsWithHtml": sorted(fetched_months), "blockedMonths": [month for month in range(1, 13) if month not in fetched_months]},
        "days": days,
        "monthDays": month_days,
        "events": legacy_events,
    }
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    for output_path in (OUT, ROOT_OUT):
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
