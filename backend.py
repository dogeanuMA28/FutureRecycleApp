from __future__ import annotations

import copy
import csv
import json
import math
import os
import re
import tempfile
from datetime import date, datetime, timedelta
from pathlib import Path
from urllib.parse import unquote

from PySide6.QtCore import QObject, Property, QStandardPaths, QUrl, Signal, Slot

MATERIALS = ("plastic", "paper", "metal")
STATUSES = ("Online", "Offline", "Maintenance")
COLLECTION_ACTIVE = ("Requested", "Scheduled")
TICKET_ACTIVE = ("Open", "In Progress")
VERSION = 5


def timestamp() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def friendly_time(iso: str) -> str:
    try:
        return datetime.fromisoformat(iso).strftime("%d %b · %H:%M")
    except (ValueError, TypeError):
        return str(iso)[:32]


def number(value, default=0, maximum=1_000_000_000) -> int:
    if isinstance(value, bool):
        return default
    try:
        result = int(value)
    except (ValueError, TypeError, OverflowError):
        return default
    return max(0, min(maximum, result))


def safe_float(value) -> float:
    try:
        result = float(value)
        return result if math.isfinite(result) else 0.0
    except (ValueError, TypeError, OverflowError):
        return 0.0


def iso_or_now(raw) -> str:
    try:
        if isinstance(raw, str):
            datetime.fromisoformat(raw)
            return raw[:40]
    except ValueError:
        pass
    return timestamp()


# Approximate city centres for fictional demo stations, not installed-device GPS.
ROMANIAN_CITIES = {
    "bucharest": (44.4268, 26.1025), "bucuresti": (44.4268, 26.1025), "bucurești": (44.4268, 26.1025),
    "cluj": (46.7712, 23.6236), "timisoara": (45.7489, 21.2087), "timișoara": (45.7489, 21.2087),
    "iasi": (47.1585, 27.6014), "iași": (47.1585, 27.6014),
    "brasov": (45.6580, 25.6012), "brașov": (45.6580, 25.6012),
    "constanta": (44.1598, 28.6348), "constanța": (44.1598, 28.6348),
    "sibiu": (45.7983, 24.1256), "oradea": (47.0465, 21.9189),
    "craiova": (44.3302, 23.7949), "arad": (46.1866, 21.3123),
    "galati": (45.4353, 28.0080), "galați": (45.4353, 28.0080),
    "ploiești": (44.9365, 26.0124), "ploiesti": (44.9365, 26.0124),
    "suceava": (47.6514, 26.2556), "bacau": (46.5711, 26.9146),
    "bacău": (46.5711, 26.9146), "targu mures": (46.5455, 24.5625),
}


def initial_coordinates(name: str, location: str, index: int) -> tuple[float, float]:
    """Best-effort city-centre demo placement; users can reposition pins on the map."""
    label = (name + " " + location).casefold()
    for city, point in ROMANIAN_CITIES.items():
        if city in label:
            return point
    # Keep the three original fictional sites in three Romanian cities on migration.
    if "central park" in label:
        return ROMANIAN_CITIES["bucharest"]
    if "university campus" in label:
        return ROMANIAN_CITIES["cluj"]
    if "green residence" in label:
        return ROMANIAN_CITIES["timisoara"]
    # Unknown city: a marked fictional location near Bucharest, not geocoding.
    return (44.4268 + .065 * (index % 4), 26.1025 + .078 * (index % 5))


def valid_romania_coordinates(lat, lon) -> bool:
    """Loose bounding box including the country and its immediate surroundings."""
    return 43.4 <= lat <= 48.5 and 20.0 <= lon <= 30.2


def sample_stations():
    return [
        {"id": "FR-001", "name": "Central Park", "location": "Bucharest, Romania", "status": "Online",
         "bins": {"plastic": 35, "paper": 58, "metal": 22},
         "counts": {"plastic": 642, "paper": 385, "metal": 257},
         "mapX": .25, "mapY": .34, "latitude": 44.4268, "longitude": 26.1025, "dailyRates": {"plastic": 6.5, "paper": 3.5, "metal": 2.1}},
        {"id": "FR-002", "name": "University Campus", "location": "Cluj-Napoca, Romania", "status": "Online",
         "bins": {"plastic": 72, "paper": 43, "metal": 18},
         "counts": {"plastic": 350, "paper": 310, "metal": 190},
         "mapX": .69, "mapY": .27, "latitude": 46.7712, "longitude": 23.6236, "dailyRates": {"plastic": 8.0, "paper": 5.0, "metal": 2.7}},
        {"id": "FR-003", "name": "Green Residence", "location": "Timișoara, Romania", "status": "Maintenance",
         "bins": {"plastic": 88, "paper": 65, "metal": 41},
         "counts": {"plastic": 200, "paper": 230, "metal": 140},
         "mapX": .57, "mapY": .72, "latitude": 45.7489, "longitude": 21.2087, "dailyRates": {"plastic": 4.0, "paper": 3.2, "metal": 2.0}},
    ]


def sample_state():
    now = datetime.now().astimezone()

    def at(minutes):
        return (now - timedelta(minutes=minutes)).isoformat(timespec="seconds")

    history = []
    for i, (sid, obj, material, confidence) in enumerate([
        ("FR-001", "Plastic Bottle", "Plastic", 97.3),
        ("FR-002", "Paper / Cardboard", "Paper", 98.1),
        ("FR-001", "Aluminum Can", "Metal", 96.5),
        ("FR-002", "Plastic Bottle", "Plastic", 97.3),
    ]):
        when = at(7 * i + 3)
        history.append({"stationId": sid, "object": obj, "material": material,
                        "confidence": confidence, "status": "Sorted", "time": friendly_time(when),
                        "createdAt": when, "demo": True})
    collections = [
        {"id": "COL-0001", "stationId": "FR-002", "material": "paper",
         "status": "Requested", "note": "Routine campus pickup request",
         "createdAt": at(32), "updatedAt": at(32), "completedAt": "",
         "scheduledFor": "", "scheduledSlot": "", "demo": True},
        {"id": "COL-0002", "stationId": "FR-001", "material": "metal",
         "status": "Completed", "note": "Routine pickup demonstration",
         "createdAt": at(4 * 24 * 60), "updatedAt": at(3 * 24 * 60),
         "completedAt": at(3 * 24 * 60), "scheduledFor": (now - timedelta(days=3)).date().isoformat(),
         "scheduledSlot": "Morning", "demo": True},
    ]
    tickets = [
        {"id": "TKT-0001", "stationId": "FR-003", "title": "Sorting mechanism inspection",
         "category": "Hardware", "priority": "High", "status": "In Progress",
         "description": "Example service ticket for the demo station.",
         "createdAt": at(90), "updatedAt": at(50), "demo": True},
        {"id": "TKT-0002", "stationId": "FR-002", "title": "Sensor calibration",
         "category": "Sensor", "priority": "Low", "status": "Resolved",
         "description": "Demonstration of a completed service request.",
         "createdAt": at(5 * 24 * 60), "updatedAt": at(4 * 24 * 60), "demo": True},
    ]
    activities = [
        {"id": "EVT-0001", "type": "Collection", "stationId": "FR-002",
         "title": "Collection requested", "details": "Paper · COL-0001", "createdAt": at(32)},
        {"id": "EVT-0002", "type": "Maintenance", "stationId": "FR-003",
         "title": "Ticket in progress", "details": "Sorting mechanism inspection · TKT-0001", "createdAt": at(50)},
        {"id": "EVT-0003", "type": "Scan", "stationId": "FR-001",
         "title": "Plastic Bottle sorted", "details": "Plastic · simulated recognition", "createdAt": at(3)},
        {"id": "EVT-0004", "type": "Scan", "stationId": "FR-002",
         "title": "Paper / Cardboard sorted", "details": "Paper · simulated recognition", "createdAt": at(10)},
        {"id": "EVT-0005", "type": "Collection", "stationId": "FR-001",
         "title": "Collection completed", "details": "Metal · COL-0002", "createdAt": at(3 * 24 * 60)},
    ]
    activities.sort(key=lambda row: row["createdAt"], reverse=True)
    return {
        "version": VERSION, "stations": sample_stations(), "selectedStationId": "FR-001",
        "nextStationNumber": 4, "history": history, "collections": collections,
        "tickets": tickets, "activity": activities, "acknowledgedAlerts": [],
        "nextCollectionNumber": 3, "nextTicketNumber": 3, "nextEventNumber": 6,
        "settings": {"scanDuration": 2000, "confidenceThreshold": 95},
        "lastScenario": "Starter Dataset", "scenarioAppliedAt": "",
    }


def _norm_list(raw, key, cap):
    entries = raw.get(key, [])
    return entries[:cap] if isinstance(entries, list) else []


def normalize_state(raw):
    """Read v2–v5 state; keep older station records and operational history."""
    if not isinstance(raw, dict) or raw.get("version") not in (2, 3, 4, VERSION):
        return sample_state()
    stations = []
    seen = set()
    for row in _norm_list(raw, "stations", 100):
        if not isinstance(row, dict):
            continue
        sid = str(row.get("id", ""))[:24]
        if not re.fullmatch(r"FR-\d{3,}", sid) or sid in seen:
            continue
        seen.add(sid)
        bins = row.get("bins") if isinstance(row.get("bins"), dict) else {}
        counts = row.get("counts") if isinstance(row.get("counts"), dict) else {}
        rates = row.get("dailyRates") if isinstance(row.get("dailyRates"), dict) else {}
        index = len(stations)
        default_coords = ((.25, .34), (.69, .27), (.57, .72))
        fallback_x, fallback_y = default_coords[index] if index < 3 else (.15 + .7 * ((index * 3) % 11) / 10, .15 + .7 * ((index * 7) % 11) / 10)
        raw_name = str(row.get("name", ""))
        raw_location = str(row.get("location", ""))
        # Older demo seeds used generic district labels with no real city.
        legacy_cities = {
            ("Central Park", "City Center"): "Bucharest, Romania",
            ("University Campus", "University District"): "Cluj-Napoca, Romania",
            ("Green Residence", "Residential Complex"): "Timișoara, Romania",
        }
        display_location = legacy_cities.get((raw_name, raw_location), raw_location)
        latitude0, longitude0 = initial_coordinates(raw_name, display_location, index)
        latitude = safe_float(row.get("latitude", latitude0))
        longitude = safe_float(row.get("longitude", longitude0))
        if not valid_romania_coordinates(latitude, longitude):
            latitude, longitude = latitude0, longitude0
        stations.append({"id": sid, "name": str(row.get("name", "Station"))[:65],
                         "location": (display_location or "Unknown")[:90],
                         "status": row.get("status") if row.get("status") in STATUSES else "Offline",
                         "bins": {k: number(bins.get(k), 0, 100) for k in MATERIALS},
                         "counts": {k: number(counts.get(k)) for k in MATERIALS},
                         "mapX": max(.07, min(.93, safe_float(row.get("mapX", fallback_x)))),
                         "mapY": max(.10, min(.90, safe_float(row.get("mapY", fallback_y)))),
                         "latitude": round(latitude, 6), "longitude": round(longitude, 6),
                         "dailyRates": {k: max(.0, min(30., safe_float(rates.get(k, {"plastic": 5.0, "paper": 3.5, "metal": 2.5}[k])))) for k in MATERIALS}})
    if not stations:
        stations = [sample_stations()[0]]
    settings = raw.get("settings") if isinstance(raw.get("settings"), dict) else {}
    speed = number(settings.get("scanDuration"), 2000)
    speed = speed if speed in (800, 2000, 3500) else 2000
    threshold = max(90, number(settings.get("confidenceThreshold"), 95, 99))
    history = []
    for row in _norm_list(raw, "history", 120):
        if isinstance(row, dict):
            when = iso_or_now(row.get("createdAt"))
            history.append({"stationId": str(row.get("stationId", ""))[:24],
                            "object": str(row.get("object", "Unknown"))[:85],
                            "material": str(row.get("material", "Unknown"))[:20],
                            "confidence": safe_float(row.get("confidence")),
                            "status": str(row.get("status", "Manual review"))[:24],
                            "time": str(row.get("time", friendly_time(when)))[:40],
                            "createdAt": when, "demo": bool(row.get("demo", False))})
    collections = []
    for row in _norm_list(raw, "collections", 400):
        if not isinstance(row, dict):
            continue
        if row.get("status") not in ("Requested", "Scheduled", "Completed", "Cancelled"):
            continue
        if row.get("material") not in MATERIALS:
            continue
        collections.append({"id": str(row.get("id", ""))[:30],
                            "stationId": str(row.get("stationId", ""))[:24],
                            "material": row["material"], "status": row["status"],
                            "note": str(row.get("note", ""))[:200],
                            "createdAt": iso_or_now(row.get("createdAt")),
                            "updatedAt": iso_or_now(row.get("updatedAt")),
                            "completedAt": str(row.get("completedAt", ""))[:40],
                            "scheduledFor": str(row.get("scheduledFor", ""))[:10],
                            "scheduledSlot": str(row.get("scheduledSlot", ""))[:16],
                            "demo": bool(row.get("demo", False))})
    tickets = []
    for row in _norm_list(raw, "tickets", 400):
        if not isinstance(row, dict):
            continue
        if row.get("status") not in ("Open", "In Progress", "Resolved"):
            continue
        tickets.append({"id": str(row.get("id", ""))[:30],
                        "stationId": str(row.get("stationId", ""))[:24],
                        "title": str(row.get("title", "Service request"))[:80],
                        "category": str(row.get("category", "Other"))[:30],
                        "priority": row.get("priority") if row.get("priority") in ("Low", "Medium", "High") else "Medium",
                        "status": row["status"], "description": str(row.get("description", ""))[:600],
                        "createdAt": iso_or_now(row.get("createdAt")),
                        "updatedAt": iso_or_now(row.get("updatedAt")),
                        "demo": bool(row.get("demo", False))})
    activity = []
    for row in _norm_list(raw, "activity", 250):
        if isinstance(row, dict):
            activity.append({"id": str(row.get("id", ""))[:30],
                             "type": str(row.get("type", "System"))[:30],
                             "stationId": str(row.get("stationId", ""))[:24],
                             "title": str(row.get("title", "Event"))[:110],
                             "details": str(row.get("details", ""))[:200],
                             "createdAt": iso_or_now(row.get("createdAt"))})
    selection = str(raw.get("selectedStationId", ""))
    if selection not in {s["id"] for s in stations}:
        selection = stations[0]["id"]

    def next_id(key, values, prefix):
        observed = [int(item["id"].split("-")[-1]) for item in values
                    if re.fullmatch(re.escape(prefix) + r"\d+", item["id"])]
        return max(number(raw.get(key), 1), max(observed, default=0) + 1)

    return {"version": VERSION, "stations": stations, "selectedStationId": selection,
            "nextStationNumber": max(number(raw.get("nextStationNumber"), 1),
                                     max(int(s["id"].split("-")[1]) for s in stations) + 1),
            "history": history, "collections": collections, "tickets": tickets,
            "activity": activity, "acknowledgedAlerts": [str(x)[:100] for x in _norm_list(raw, "acknowledgedAlerts", 300) if isinstance(x, str)],
            "nextCollectionNumber": next_id("nextCollectionNumber", collections, "COL-"),
            "nextTicketNumber": next_id("nextTicketNumber", tickets, "TKT-"),
            "nextEventNumber": next_id("nextEventNumber", activity, "EVT-"),
            "settings": {"scanDuration": speed, "confidenceThreshold": threshold},
            "lastScenario": str(raw.get("lastScenario", "Legacy Data"))[:40],
            "scenarioAppliedAt": str(raw.get("scenarioAppliedAt", ""))[:40]}

def load_demo_seed():
    """Load the shared demonstration data from the repository."""

    seed_path = (
        Path(__file__).resolve().parent
        / "data"
        / "demo_seed.json"
    )

    try:
        with seed_path.open("r", encoding="utf-8") as file:
            raw = json.load(file)

        if not isinstance(raw, dict):
            raise ValueError("Demo data must be a JSON object")

        if raw.get("version") not in (2, 3, 4, VERSION):
            raise ValueError("Unsupported demo data version")

        if not isinstance(raw.get("stations"), list) or not raw["stations"]:
            raise ValueError("Demo data must contain stations")

        print(f"Loaded shared demo data from: {seed_path}")

        return normalize_state(raw)

    except (OSError, ValueError, TypeError) as error:
        print(f"Could not load demo seed: {error}")
        print("Using built-in demonstration data instead.")

        return sample_state()

def classify_filename(filename):
    """Keywords in the filename ONLY, never image pixel recognition."""
    name = filename.lower()
    if re.search(r"plastic|bottle|pet|sticla", name):
        return {"object": "Plastic Bottle", "material": "Plastic", "confidence": 97.3}
    if re.search(r"paper|cardboard|carton|hartie", name):
        return {"object": "Paper / Cardboard", "material": "Paper", "confidence": 98.1}
    if re.search(r"metal|aluminum|aluminium|doza|(?:^|[_\-.])can(?:[_\-.]|$)", name):
        return {"object": "Aluminum Can", "material": "Metal", "confidence": 96.5}
    return {"object": "Unrecognized Object", "material": "Unknown", "confidence": 0.0}


def _in_period(iso, period):
    if period == "all":
        return True
    try:
        dt = datetime.fromisoformat(iso)
        if dt.tzinfo is None:
            dt = dt.astimezone()
        cutoff = datetime.now().astimezone() - timedelta(days=7 if period == "7d" else 30)
        return dt >= cutoff
    except (TypeError, ValueError):
        return False


class Backend(QObject):
    stateChanged = Signal()
    notice = Signal(str)

    def __init__(self, parent=None, data_file=None):
        super().__init__(parent)
        base = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
        self.data_dir = Path(base) if base else Path.home() / ".local/share/FutureRecycle"
        self.data_file = Path(data_file) if data_file else self.data_dir / "state.json"
        self.data_dir = self.data_file.parent
        self._state = self._load()
        # Create a personal local copy on the first launch.
        if not self.data_file.exists():
            self._save()
        print(f"FutureRecycle state file: {self.data_file}")


    @Property("QVariantMap", notify=stateChanged)
    def state(self):
        result = copy.deepcopy(self._state)
        result["alerts"] = self._alerts()
        result["forecasts"] = self._forecasts()
        return result

    def _load(self):
        # 1. Always prefer the user's existing saved data.
        if self.data_file.exists():
            try:
                saved = json.loads(
                    self.data_file.read_text(encoding="utf-8")
                )

                return normalize_state(saved)

            except (OSError, ValueError, TypeError) as error:
                print("Unable to load local state:", error)

        # 2. If there is no usable local save,
        #    initialize the app from the shared demo dataset.
        return load_demo_seed()

    def _save(self):
        tmp = None
        try:
            self.data_dir.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=self.data_dir,
                                             suffix=".tmp", delete=False) as fh:
                tmp = fh.name
                json.dump(self._state, fh, ensure_ascii=False, indent=2)
                fh.flush()
                os.fsync(fh.fileno())
            os.replace(tmp, self.data_file)
        except OSError as exc:
            print("Could not save state:", exc)
            self.notice.emit("Unable to save changes to disk.")
        finally:
            if tmp and os.path.exists(tmp):
                os.unlink(tmp)

    def _commit(self, message=""):
        active_ids = {alert["id"] for alert in self._alerts()}
        self._state["acknowledgedAlerts"] = [x for x in self._state["acknowledgedAlerts"] if x in active_ids]
        self._save()
        self.stateChanged.emit()
        if message:
            self.notice.emit(message)

    def _station(self, sid):
        return next((s for s in self._state["stations"] if s["id"] == sid), None)

    def _log(self, typ, sid, title, details=""):
        event_id = f"EVT-{self._state['nextEventNumber']:04d}"
        self._state["nextEventNumber"] += 1
        self._state["activity"].insert(0, {"id": event_id, "type": typ,
                                           "stationId": sid, "title": title[:110],
                                           "details": details[:200], "createdAt": timestamp()})
        self._state["activity"] = self._state["activity"][:200]

    def _alerts(self):
        out = []
        acknowledged = set(self._state.get("acknowledgedAlerts", []))
        for s in self._state["stations"]:
            if s["status"] != "Online":
                aid = f"status:{s['id']}"
                out.append({"id": aid, "type": "status", "stationId": s["id"],
                            "stationName": s["name"], "title": f"Station {s['status'].lower()}",
                            "detail": "Station requires attention", "material": "",
                            "severity": "High" if s["status"] == "Offline" else "Medium",
                            "acknowledged": aid in acknowledged})
            for material in MATERIALS:
                fill = s["bins"][material]
                if fill >= 80:
                    aid = f"fill:{s['id']}:{material}"
                    out.append({"id": aid, "type": "fill", "stationId": s["id"],
                                "stationName": s["name"], "title": f"{material.title()} bin at {fill}%",
                                "detail": "Request collection to clear this container", "material": material,
                                "severity": "High" if fill >= 95 else "Medium",
                                "acknowledged": aid in acknowledged})
        for t in self._state["tickets"]:
            if t["status"] in TICKET_ACTIVE and t["priority"] == "High":
                aid = f"ticket:{t['id']}"
                out.append({"id": aid, "type": "ticket", "stationId": t["stationId"],
                            "stationName": (self._station(t["stationId"]) or {}).get("name", t["stationId"]),
                            "title": t["title"], "detail": f"{t['id']} · {t['status']}", "material": "",
                            "severity": "High", "acknowledged": aid in acknowledged})
        out.sort(key=lambda a: (a["acknowledged"], a["severity"] != "High", a["stationId"]))
        return out

    def _forecasts(self):
        """Simple straight-line forecasts from configured DEMO daily fill rates."""
        forecasts = []
        today = datetime.now().astimezone()
        for s in self._state["stations"]:
            for material in MATERIALS:
                level = s["bins"][material]
                rate = s["dailyRates"][material]
                days = round(max(0., (100. - level) / rate), 1) if rate > 0 else -1.
                projected = (today + timedelta(days=days)).date().isoformat() if days >= 0 else ""
                urgency = "Critical" if level >= 95 or (days >= 0 and days <= 1) else (
                    "Soon" if days >= 0 and days <= 3 else "Normal")
                forecasts.append({"stationId": s["id"], "stationName": s["name"],
                                  "material": material, "fill": level, "dailyRate": rate,
                                  "daysRemaining": days, "projectedDate": projected,
                                  "urgency": urgency})
        forecasts.sort(key=lambda x: (x["daysRemaining"] < 0, x["daysRemaining"] if x["daysRemaining"] >= 0 else 99999))
        return forecasts

    @Slot(str, float, float)
    def setStationPosition(self, sid, x, y):
        s = self._station(sid)
        if s and math.isfinite(x) and math.isfinite(y):
            s["mapX"] = round(max(.07, min(.93, float(x))), 4)
            s["mapY"] = round(max(.10, min(.90, float(y))), 4)
            self._commit(f"{sid} map pin updated (illustrative placement).")

    @Slot(str, float, float, result=bool)
    def setStationCoordinates(self, sid, latitude, longitude):
        """Reposition a fictional station on the Romania map, without geocoding."""
        s = self._station(sid)
        if not s or not all(math.isfinite(v) for v in (latitude, longitude)):
            return False
        if not valid_romania_coordinates(latitude, longitude):
            self.notice.emit("Please place the demo marker within Romania.")
            return False
        s["latitude"] = round(float(latitude), 6)
        s["longitude"] = round(float(longitude), 6)
        self._log("Station", sid, "Map location updated", "Approximate demo position")
        self._commit(f"{sid} map location saved (fictional demo placement).")
        return True

    @Slot(str, str, float)
    def setDailyFillRate(self, sid, material, rate):
        s = self._station(sid)
        if s and material in MATERIALS and math.isfinite(rate):
            s["dailyRates"][material] = round(max(0., min(30., float(rate))), 1)
            self._commit(f"{sid}: updated simulated {material} fill rate.")

    @Slot(str)
    def acknowledgeAlert(self, alert_id):
        if alert_id in {a["id"] for a in self._alerts()} and alert_id not in self._state["acknowledgedAlerts"]:
            self._state["acknowledgedAlerts"].append(alert_id)
            self._log("System", "", "Alert acknowledged", alert_id)
            self._commit("Alert acknowledged. It remains active until resolved.")

    @Slot(str)
    def selectStation(self, sid):
        if self._station(sid):
            self._state["selectedStationId"] = sid
            self._commit()

    @Slot(str, str, result=str)
    def addStation(self, name, location):
        name, location = name.strip()[:65], location.strip()[:90]
        if not name or not location:
            self.notice.emit("Enter a station name and location.")
            return ""
        sid = f"FR-{self._state['nextStationNumber']:03d}"
        self._state["nextStationNumber"] += 1
        lat, lon = initial_coordinates(name, location, len(self._state["stations"]))
        self._state["stations"].append({"id": sid, "name": name, "location": location,
                                        "latitude": lat, "longitude": lon,
                                        "status": "Online", "bins": {k: 0 for k in MATERIALS},
                                        "counts": {k: 0 for k in MATERIALS},
                                        "mapX": round(.15 + .7 * ((self._state["nextStationNumber"] * 3) % 11) / 10, 3),
                                        "mapY": round(.15 + .7 * ((self._state["nextStationNumber"] * 7) % 11) / 10, 3),
                                        "dailyRates": {"plastic": 5.0, "paper": 3.5, "metal": 2.5}})
        self._state["selectedStationId"] = sid
        self._log("Station", sid, "Station added", name)
        self._commit(f"{name} added to the network.")
        return sid

    @Slot(str, result=bool)
    def removeStation(self, sid):
        s = self._station(sid)
        if not s:
            return False
        if len(self._state["stations"]) <= 1:
            self.notice.emit("At least one station must remain.")
            return False
        if any(job["stationId"] == sid and job["status"] in COLLECTION_ACTIVE for job in self._state["collections"]):
            self.notice.emit("Cancel or complete this station's pending collections first.")
            return False
        if any(t["stationId"] == sid and t["status"] in TICKET_ACTIVE for t in self._state["tickets"]):
            self.notice.emit("Resolve this station's open maintenance tickets first.")
            return False
        self._state["stations"] = [s for s in self._state["stations"] if s["id"] != sid]
        if self._state["selectedStationId"] == sid:
            self._state["selectedStationId"] = self._state["stations"][0]["id"]
        self._log("Station", sid, "Station removed", s["name"])
        self._commit(f"Removed {sid}. Historical records retained.")
        return True

    @Slot(str, str)
    def setStatus(self, sid, status):
        s = self._station(sid)
        if s and status in STATUSES and status != s["status"]:
            s["status"] = status
            self._log("Station", sid, "Station status changed", status)
            self._commit(f"{sid} is now {status.lower()}.")

    def _empty(self, sid, material, manual=True):
        s = self._station(sid)
        if not s or material not in MATERIALS:
            return False
        s["bins"][material] = 0
        if manual:
            for job in self._state["collections"]:
                if job["stationId"] == sid and job["material"] == material and job["status"] in COLLECTION_ACTIVE:
                    job["status"] = "Cancelled"
                    job["updatedAt"] = timestamp()
                    self._log("Collection", sid, "Collection cancelled", f"{material.title()} · {job['id']} · manually emptied")
            self._log("Station", sid, "Container manually emptied", material.title())
        return True

    @Slot(str, str)
    def emptyBin(self, sid, material):
        if self._empty(sid, material.lower()):
            self._commit(f"{sid} · {material.title()} bin emptied.")

    @Slot(str)
    def emptyStation(self, sid):
        if self._station(sid):
            for material in MATERIALS:
                self._empty(sid, material)
            self._commit(f"All containers at {sid} emptied.")

    @Slot()
    def emptyAllStations(self):
        for s in self._state["stations"]:
            for material in MATERIALS:
                self._empty(s["id"], material)
        self._commit("All virtual containers emptied.")

    @Slot(int)
    def setScanDuration(self, duration):
        if duration in (800, 2000, 3500):
            self._state["settings"]["scanDuration"] = duration
            self._commit()

    @Slot(int)
    def setConfidenceThreshold(self, threshold):
        self._state["settings"]["confidenceThreshold"] = max(90, min(99, int(threshold)))
        self._commit()

    @Slot(str, result="QVariantMap")
    def scanFile(self, url):
        return self.scanFileAtStation(url, self._state["selectedStationId"])

    @Slot(str, str, result="QVariantMap")
    def scanFileAtStation(self, url, sid):
        s = self._station(sid)
        if not s or s["status"] != "Online":
            self.notice.emit("Choose an online station before scanning.")
            return {"object": "Not processed", "material": "Unknown", "confidence": 0.0,
                    "stationId": sid, "destination": "Unavailable", "status": "Unavailable"}
        local = QUrl(url).toLocalFile() if str(url).startswith("file:") else unquote(str(url))
        result = classify_filename(Path(local).name)
        sorted_ok = (result["material"] != "Unknown" and
                     result["confidence"] >= self._state["settings"]["confidenceThreshold"])
        material = result["material"]
        result.update({"stationId": sid, "destination": f"{sid} · {material} bin" if sorted_ok else "Manual review",
                       "status": "Sorted" if sorted_ok else "Manual review"})
        if sorted_ok:
            key = material.lower()
            s["counts"][key] += 1
            s["bins"][key] = min(100, s["bins"][key] + 5)
        when = timestamp()
        self._state["history"].insert(0, {"stationId": sid, "object": result["object"],
                                          "material": material, "confidence": result["confidence"],
                                          "status": result["status"], "createdAt": when,
                                          "time": friendly_time(when), "demo": False})
        self._state["history"] = self._state["history"][:120]
        self._log("Scan", sid, f"{result['object']} · {result['status']}", f"{material} · filename-based simulated detection")
        self._commit(f"{result['object']} · {result['status'].lower()} at {sid}.")
        return result

    @Slot(str, str, str, result=str)
    def requestCollection(self, sid, material, note):
        material = material.lower()
        s = self._station(sid)
        if not s or material not in MATERIALS:
            self.notice.emit("Select a valid station and material.")
            return ""
        if s["bins"][material] <= 0:
            self.notice.emit("This container is already empty.")
            return ""
        if any(x["stationId"] == sid and x["material"] == material and x["status"] in COLLECTION_ACTIVE
               for x in self._state["collections"]):
            self.notice.emit("A collection for this container is already pending.")
            return ""
        job_id = f"COL-{self._state['nextCollectionNumber']:04d}"
        self._state["nextCollectionNumber"] += 1
        now = timestamp()
        self._state["collections"].insert(0, {"id": job_id, "stationId": sid, "material": material,
                                               "note": note.strip()[:200], "status": "Requested",
                                               "createdAt": now, "updatedAt": now,
                                               "completedAt": "", "scheduledFor": "", "scheduledSlot": "", "demo": False})
        self._state["collections"] = self._state["collections"][:400]
        self._log("Collection", sid, "Collection requested", f"{material.title()} · {job_id}")
        self._commit(f"Collection {job_id} requested (simulation).")
        return job_id

    @Slot(str, str, str, result=bool)
    def scheduleCollection(self, job_id, day_string, slot):
        job = next((x for x in self._state["collections"] if x["id"] == job_id), None)
        if not job or job["status"] not in ("Requested", "Scheduled"):
            self.notice.emit("Only requested or scheduled pickups can be scheduled.")
            return False
        try:
            chosen = date.fromisoformat(day_string)
        except (TypeError, ValueError):
            self.notice.emit("Choose a valid collection date.")
            return False
        today = date.today()
        if chosen < today or chosen > today + timedelta(days=365):
            self.notice.emit("Choose a date between today and one year ahead.")
            return False
        if slot not in ("Morning", "Afternoon", "Evening"):
            self.notice.emit("Choose a pickup time window.")
            return False
        job["scheduledFor"] = chosen.isoformat()
        job["scheduledSlot"] = slot
        job["status"] = "Scheduled"
        job["updatedAt"] = timestamp()
        self._log("Collection", job["stationId"], "Collection scheduled",
                  f"{job_id} · {chosen.isoformat()} · {slot}")
        self._commit(f"{job_id} scheduled for {chosen.isoformat()} ({slot.lower()}).")
        return True

    @Slot(str, str, result=bool)
    def setCollectionStatus(self, job_id, new_status):
        job = next((x for x in self._state["collections"] if x["id"] == job_id), None)
        if not job:
            return False
        transitions = {"Requested": ("Scheduled", "Cancelled"),
                       "Scheduled": ("Completed", "Cancelled")}
        if new_status not in transitions.get(job["status"], ()):
            self.notice.emit("Invalid collection status transition.")
            return False
        if new_status == "Scheduled":
            return self.scheduleCollection(job_id, (date.today() + timedelta(days=1)).isoformat(), "Morning")
        if new_status == "Completed":
            if not job.get("scheduledFor"):
                self.notice.emit("Schedule the collection before marking it complete.")
                return False
            if not self._empty(job["stationId"], job["material"], manual=False):
                self.notice.emit("Station no longer exists.")
                return False
            job["completedAt"] = timestamp()
        job["status"] = new_status
        job["updatedAt"] = timestamp()
        self._log("Collection", job["stationId"], f"Collection {new_status.lower()}",
                  f"{job['material'].title()} · {job_id}")
        self._commit(f"{job_id} marked {new_status.lower()} (simulation).")
        return True

    @Slot(str, str, str, str, str, result=str)
    def createTicket(self, sid, title, category, priority, description):
        if not self._station(sid) or not title.strip():
            self.notice.emit("Choose a station and enter a ticket title.")
            return ""
        ticket_id = f"TKT-{self._state['nextTicketNumber']:04d}"
        self._state["nextTicketNumber"] += 1
        now = timestamp()
        ticket = {"id": ticket_id, "stationId": sid,
                  "title": title.strip()[:80], "category": category if category in ("Hardware", "Sensor", "Connectivity", "Other") else "Other",
                  "priority": priority if priority in ("Low", "Medium", "High") else "Medium",
                  "status": "Open", "description": description.strip()[:600],
                  "createdAt": now, "updatedAt": now, "demo": False}
        self._state["tickets"].insert(0, ticket)
        self._state["tickets"] = self._state["tickets"][:400]
        self._log("Maintenance", sid, "Service ticket created", f"{ticket_id} · {ticket['title']}")
        self._commit(f"Ticket {ticket_id} created (simulation).")
        return ticket_id

    @Slot(str, str, result=bool)
    def setTicketStatus(self, ticket_id, new_status):
        ticket = next((x for x in self._state["tickets"] if x["id"] == ticket_id), None)
        transitions = {"Open": ("In Progress", "Resolved"),
                       "In Progress": ("Resolved",), "Resolved": ("Open",)}
        if not ticket or new_status not in transitions.get(ticket["status"], ()):
            self.notice.emit("Invalid ticket status transition.")
            return False
        ticket["status"] = new_status
        ticket["updatedAt"] = timestamp()
        self._log("Maintenance", ticket["stationId"], f"Ticket {new_status.lower()}",
                  f"{ticket_id} · {ticket['title']}")
        self._commit(f"{ticket_id}: {new_status}.")
        return True

    def _rows_for_report(self, sid, period):
        rows = []
        for s in self._state["stations"]:
            if sid not in ("all", s["id"]):
                continue
            scans = [x for x in self._state["history"] if x["stationId"] == s["id"] and _in_period(x["createdAt"], period)]
            pickups = [x for x in self._state["collections"] if x["stationId"] == s["id"] and
                       x["status"] == "Completed" and _in_period(x["completedAt"], period)]
            resolved = [x for x in self._state["tickets"] if x["stationId"] == s["id"] and
                        x["status"] == "Resolved" and _in_period(x["updatedAt"], period)]
            rows.append({"stationId": s["id"], "name": s["name"], "location": s["location"],
                         "status": s["status"], "plastic": s["counts"]["plastic"],
                         "paper": s["counts"]["paper"], "metal": s["counts"]["metal"],
                         "total": sum(s["counts"].values()), "plasticFill": s["bins"]["plastic"],
                         "paperFill": s["bins"]["paper"], "metalFill": s["bins"]["metal"],
                         "sortedScans": sum(x["status"] == "Sorted" for x in scans),
                         "manualReviews": sum(x["status"] == "Manual review" for x in scans),
                         "completedPickups": len(pickups), "resolvedTickets": len(resolved)})
        return rows

    @Slot(str, str, result="QVariantMap")
    def reportSummary(self, station_id, period):
        if period not in ("7d", "30d", "all"):
            period = "30d"
        rows = self._rows_for_report(station_id, period)
        return {"rows": rows, "stationCount": len(rows),
                "lifetimeItems": sum(x["total"] for x in rows),
                "sortedScans": sum(x["sortedScans"] for x in rows),
                "manualReviews": sum(x["manualReviews"] for x in rows),
                "completedPickups": sum(x["completedPickups"] for x in rows),
                "resolvedTickets": sum(x["resolvedTickets"] for x in rows),
                "period": period}

    @Slot(str, str, str, result=bool)
    def exportReport(self, url, station_id, period):
        if period not in ("7d", "30d", "all"):
            period = "30d"
        file_path = QUrl(url).toLocalFile() if str(url).startswith("file:") else str(url)
        if not file_path:
            self.notice.emit("Choose a CSV destination first.")
            return False
        path = Path(file_path)
        if path.suffix.lower() != ".csv":
            path = path.with_suffix(".csv")
        fields = ["stationId", "name", "location", "status", "plastic", "paper", "metal", "total",
                  "plasticFill", "paperFill", "metalFill", "sortedScans", "manualReviews",
                  "completedPickups", "resolvedTickets"]
        try:
            with path.open("w", newline="", encoding="utf-8-sig") as handle:
                writer = csv.DictWriter(handle, fieldnames=fields)
                writer.writeheader()
                writer.writerows(self._rows_for_report(station_id, period))
        except OSError as exc:
            print("Report export error:", exc)
            self.notice.emit("CSV export failed. Check the folder permissions.")
            return False
        self._log("System", "", "CSV report exported", f"Scope: {station_id} · {period}")
        self._commit(f"Report exported to {path.name}.")
        return True

    @Slot(str, result=bool)
    def applyScenario(self, scenario):
        """Deterministic demo preset, never a real-world instruction or dispatch."""
        if scenario not in ("Normal", "Busy", "Critical", "Recovery"):
            self.notice.emit("Unknown presentation scenario.")
            return False
        stations = self._state["stations"]
        if not stations:
            return False
        # Stop older pending simulations from hiding the scenario's behavior.
        if scenario != "Recovery":
            for job in self._state["collections"]:
                if job["status"] in COLLECTION_ACTIVE:
                    job["status"] = "Cancelled"
                    job["updatedAt"] = timestamp()
            for ticket in self._state["tickets"]:
                if ticket["status"] in TICKET_ACTIVE:
                    ticket["status"] = "Resolved"
                    ticket["updatedAt"] = timestamp()
        if scenario == "Normal":
            fills = (24, 37, 16)
        elif scenario == "Busy":
            fills = (86, 75, 67)
        elif scenario == "Critical":
            fills = (99, 95, 82)
        else:
            fills = (14, 22, 11)
        completed_containers = []
        if scenario == "Recovery":
            for job in self._state["collections"]:
                if job["status"] in COLLECTION_ACTIVE and self._station(job["stationId"]):
                    completed_containers.append((job["stationId"], job["material"]))
                    job["status"] = "Completed"
                    job["scheduledFor"] = job.get("scheduledFor") or date.today().isoformat()
                    job["scheduledSlot"] = job.get("scheduledSlot") or "Morning"
                    job["updatedAt"] = timestamp()
                    job["completedAt"] = timestamp()
                    self._log("Collection", job["stationId"], "Presentation pickup completed", job["id"])
            for ticket in self._state["tickets"]:
                if ticket["status"] in TICKET_ACTIVE:
                    ticket["status"] = "Resolved"
                    ticket["updatedAt"] = timestamp()
                    self._log("Maintenance", ticket["stationId"], "Presentation ticket resolved", ticket["id"])
        for i, s in enumerate(stations):
            s["status"] = "Offline" if scenario == "Critical" and i == len(stations) - 1 else "Online"
            for j, material in enumerate(MATERIALS):
                # Vary by station; keep critical alerts visible on multiple bins.
                offset = (i * 7) if scenario in ("Normal", "Recovery") else (i * 2)
                s["bins"][material] = min(100, max(0, fills[j] + offset))
        # The completed collections in Recovery must actually empty their bins.
        for sid, material in completed_containers:
            station = self._station(sid)
            if station:
                station["bins"][material] = 0
        if scenario == "Critical":
            last = stations[-1]
            if not any(t["stationId"] == last["id"] and t["priority"] == "High" and
                       t["status"] in TICKET_ACTIVE for t in self._state["tickets"]):
                ticket_id = f"TKT-{self._state['nextTicketNumber']:04d}"
                self._state["nextTicketNumber"] += 1
                self._state["tickets"].insert(0, {"id": ticket_id, "stationId": last["id"],
                        "title": "Simulated connectivity failure", "category": "Connectivity",
                        "priority": "High", "status": "Open",
                        "description": "Presentation scenario only. No actual device is affected.",
                        "createdAt": timestamp(), "updatedAt": timestamp(), "demo": True})
        self._state["lastScenario"] = scenario
        self._state["scenarioAppliedAt"] = timestamp()
        self._state["acknowledgedAlerts"] = []
        self._log("System", "", "Presentation scenario applied", scenario)
        self._commit(f"{scenario} scenario applied to the demo network.")
        return True

    @Slot()
    def resetStatistics(self):
        for s in self._state["stations"]:
            s["counts"] = {k: 0 for k in MATERIALS}
            s["bins"] = {k: 0 for k in MATERIALS}
        self._state["history"] = []
        self._state["collections"] = []
        self._state["tickets"] = []
        self._state["lastScenario"] = "Reset Data"
        self._state["scenarioAppliedAt"] = ""
        self._state["acknowledgedAlerts"] = []
        self._state["activity"] = []
        self._log("System", "", "Simulation reset", "All statistics and operational records cleared")
        self._commit("Simulation statistics and operations reset.")

    @Slot()
    def restoreDemo(self):
        # Preserve the user's preferred simulation settings.
        settings = copy.deepcopy(
            self._state["settings"]
        )

        # Restore the dataset committed to GitHub.
        self._state = load_demo_seed()

        self._state["settings"] = settings

        self._commit(
            "Shared demonstration dataset restored."
        )

