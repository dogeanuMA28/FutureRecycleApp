"""Run inside the project environment: python -m unittest discover -s tests -v"""
import csv
import json
import tempfile
import unittest
from pathlib import Path

from backend import Backend, normalize_state, VERSION


class FutureRecycleBackendTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "state.json"
        self.app = Backend(data_file=self.path)

    def tearDown(self):
        self.temp.cleanup()

    def test_station_management_and_scan(self):
        sid = self.app.addStation("Harbor Square", "South District")
        self.assertEqual(sid, "FR-004")
        result = self.app.scanFileAtStation("file:///tmp/plastic_bottle.jpg", sid)
        self.assertEqual(result["status"], "Sorted")
        station = self.app._station(sid)
        self.assertEqual(station["bins"]["plastic"], 5)
        self.assertEqual(station["counts"]["plastic"], 1)
        self.assertEqual(self.app.scanFileAtStation("file:///tmp/mystery.png", sid)["status"], "Manual review")

    def test_collection_lifecycle_and_duplicate_protection(self):
        # FR-003 plastic is 88% full, and its seeded job concerns a different station.
        job = self.app.requestCollection("FR-003", "plastic", "Need pickup")
        self.assertTrue(job)
        self.assertEqual(self.app.requestCollection("FR-003", "plastic", "Duplicate"), "")
        self.assertTrue(self.app.setCollectionStatus(job, "Scheduled"))
        self.assertTrue(self.app.setCollectionStatus(job, "Completed"))
        self.assertEqual(self.app._station("FR-003")["bins"]["plastic"], 0)
        self.assertFalse(self.app.setCollectionStatus(job, "Completed"))
        self.assertNotIn("fill:FR-003:plastic", [a["id"] for a in self.app.state["alerts"]])

    def test_acknowledged_alerts_and_ticket_workflow(self):
        sid = "FR-003"
        alert_id = "fill:FR-003:plastic"
        self.assertIn(alert_id, [a["id"] for a in self.app.state["alerts"]])
        self.app.acknowledgeAlert(alert_id)
        self.assertTrue(next(a for a in self.app.state["alerts"] if a["id"] == alert_id)["acknowledged"])
        self.app.emptyBin(sid, "plastic")
        self.assertNotIn(alert_id, self.app._state["acknowledgedAlerts"])
        ticket_id = self.app.createTicket("FR-002", "Screen damaged", "Hardware", "High", "Cracked screen")
        self.assertIn(f"ticket:{ticket_id}", [a["id"] for a in self.app.state["alerts"]])
        self.assertTrue(self.app.setTicketStatus(ticket_id, "In Progress"))
        self.assertTrue(self.app.setTicketStatus(ticket_id, "Resolved"))
        self.assertNotIn(f"ticket:{ticket_id}", [a["id"] for a in self.app.state["alerts"]])

    def test_report_export_and_persistence(self):
        job = self.app.requestCollection("FR-003", "plastic", "Pickup")
        self.app.setCollectionStatus(job, "Scheduled")
        self.app.setCollectionStatus(job, "Completed")
        rows = self.app.reportSummary("all", "30d")
        self.assertGreaterEqual(rows["completedPickups"], 1)
        output = Path(self.temp.name) / "report.csv"
        self.assertTrue(self.app.exportReport(str(output), "all", "30d"))
        with output.open(encoding="utf-8-sig", newline="") as fh:
            report = list(csv.DictReader(fh))
        self.assertEqual(len(report), 3)
        self.assertEqual(len(report[0]), 15)
        restored = Backend(data_file=self.path)
        self.assertEqual(restored._station("FR-003")["bins"]["plastic"], 0)
        self.assertEqual(restored.reportSummary("all", "30d")["completedPickups"], rows["completedPickups"])

    def test_migrate_version_two(self):
        v2 = {"version": 2, "stations": [{"id": "FR-010", "name": "Old Site", "location": "Downtown",
               "status": "Online", "bins": {"plastic": 40}, "counts": {"plastic": 100}}],
              "nextStationNumber": 11, "selectedStationId": "FR-010", "history": [],
              "settings": {"scanDuration": 800, "confidenceThreshold": 97}}
        result = normalize_state(v2)
        self.assertEqual(result["version"], VERSION)
        self.assertEqual(result["stations"][0]["counts"]["plastic"], 100)
        self.assertEqual(result["settings"]["scanDuration"], 800)
        self.assertEqual(result["collections"], [])

    def test_calendar_schedule_validation_and_persistence(self):
        from datetime import date, timedelta
        jid = self.app.requestCollection("FR-003", "plastic", "Calendar booking")
        self.assertTrue(jid)
        self.assertFalse(self.app.scheduleCollection(jid, "nonsense", "Morning"))
        past = (date.today() - timedelta(days=1)).isoformat()
        self.assertFalse(self.app.scheduleCollection(jid, past, "Morning"))
        chosen = (date.today() + timedelta(days=5)).isoformat()
        self.assertFalse(self.app.scheduleCollection(jid, chosen, "Midnight"))
        self.assertTrue(self.app.scheduleCollection(jid, chosen, "Afternoon"))
        self.assertTrue(self.app.scheduleCollection(jid, chosen, "Evening"))
        job = next(x for x in self.app.state["collections"] if x["id"] == jid)
        self.assertEqual(job["scheduledFor"], chosen)
        self.assertEqual(job["scheduledSlot"], "Evening")
        restored = Backend(data_file=self.path)
        saved = next(x for x in restored.state["collections"] if x["id"] == jid)
        self.assertEqual(saved["scheduledFor"], chosen)
        self.assertTrue(restored.setCollectionStatus(jid, "Completed"))
        self.assertEqual(restored._station("FR-003")["bins"]["plastic"], 0)

    def test_forecasts_and_map_positions(self):
        sid = "FR-001"
        original = next(f for f in self.app.state["forecasts"] if f["stationId"] == sid and f["material"] == "plastic")
        self.assertGreater(original["daysRemaining"], 0)
        self.app.setDailyFillRate(sid, "plastic", 0)
        missing = next(f for f in self.app.state["forecasts"] if f["stationId"] == sid and f["material"] == "plastic")
        self.assertEqual(missing["daysRemaining"], -1)
        self.app.setDailyFillRate(sid, "plastic", 20)
        projected = next(f for f in self.app.state["forecasts"] if f["stationId"] == sid and f["material"] == "plastic")
        self.assertLess(projected["daysRemaining"], original["daysRemaining"])
        self.app.setStationPosition(sid, 0.72, 0.61)
        restored = Backend(data_file=self.path)
        station = restored._station(sid)
        self.assertAlmostEqual(station["mapX"], .72)
        self.assertAlmostEqual(station["mapY"], .61)
        self.assertEqual(station["dailyRates"]["plastic"], 20)

    def test_scenarios_generate_and_resolve_alerts(self):
        self.assertTrue(self.app.applyScenario("Normal"))
        self.assertEqual(self.app.state["alerts"], [])
        self.assertTrue(self.app.applyScenario("Busy"))
        self.assertTrue(any(a["type"] == "fill" for a in self.app.state["alerts"]))
        self.assertTrue(self.app.applyScenario("Critical"))
        self.assertTrue(any(a["type"] == "status" for a in self.app.state["alerts"]))
        self.assertTrue(any(t["status"] == "Open" and t["priority"] == "High" for t in self.app.state["tickets"]))
        self.assertTrue(self.app.applyScenario("Recovery"))
        self.assertEqual(self.app.state["alerts"], [])
        self.assertEqual(self.app.state["lastScenario"], "Recovery")
        self.assertFalse(self.app.applyScenario("Inexistent"))

    def test_upgrade_version_three_keeps_records(self):
        older = {"version": 3, "stations": [{"id": "FR-007", "name": "Legacy", "location": "City",
                 "status": "Online", "bins": {"plastic": 87}, "counts": {"plastic": 17}}],
                 "selectedStationId": "FR-007", "nextStationNumber": 8,
                 "collections": [{"id": "COL-0010", "stationId": "FR-007", "material": "plastic",
                                  "status": "Scheduled", "note": "Old request", "createdAt": "2026-04-20T12:00:00+02:00",
                                  "updatedAt": "2026-04-20T12:00:00+02:00", "completedAt": ""}]}
        migrated = normalize_state(older)
        self.assertEqual(migrated["version"], VERSION)
        self.assertEqual(migrated["stations"][0]["counts"]["plastic"], 17)
        self.assertGreater(migrated["stations"][0]["dailyRates"]["plastic"], 0)
        self.assertEqual(migrated["collections"][0]["status"], "Scheduled")
        self.assertEqual(migrated["collections"][0]["scheduledFor"], "")

    def test_manual_empty_cancels_open_job(self):
        jid = self.app.requestCollection("FR-003", "plastic", "")
        self.app.emptyBin("FR-003", "plastic")
        job = next(x for x in self.app.state["collections"] if x["id"] == jid)
        self.assertEqual(job["status"], "Cancelled")

    def test_reset_restores_network(self):
        self.app.resetStatistics()
        self.assertEqual(self.app.state["tickets"], [])
        self.assertEqual(self.app.state["collections"], [])
        self.app.restoreDemo()
        self.assertEqual(len(self.app.state["stations"]), 3)
        self.assertGreater(len(self.app.state["tickets"]), 0)
        self.assertGreater(len(self.app.state["collections"]), 0)


if __name__ == "__main__":
    unittest.main()

# Additional geographic mapping regression tests (v1.3).
class RomaniaMapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / 'state.json'
        self.app = Backend(data_file=self.path)

    def tearDown(self):
        self.temp.cleanup()

    def test_seeded_coordinates_are_in_romania(self):
        coords = [(s['latitude'], s['longitude']) for s in self.app.state['stations']]
        self.assertEqual(len(set(coords)), 3)
        for lat, lon in coords:
            self.assertTrue(43.4 <= lat <= 48.5)
            self.assertTrue(20.0 <= lon <= 30.2)
        self.assertAlmostEqual(self.app._station('FR-001')['latitude'], 44.4268)
        self.assertAlmostEqual(self.app._station('FR-002')['latitude'], 46.7712)

    def test_reposition_saved_coordinates_and_reject_invalid(self):
        self.assertTrue(self.app.setStationCoordinates('FR-001', 45.6580, 25.6012))
        self.assertFalse(self.app.setStationCoordinates('FR-001', 1.0, 2.0))
        self.assertFalse(self.app.setStationCoordinates('FR-000', 45.0, 24.0))
        again = Backend(data_file=self.path)
        self.assertAlmostEqual(again._station('FR-001')['latitude'], 45.6580)
        self.assertAlmostEqual(again._station('FR-001')['longitude'], 25.6012)

    def test_new_station_initially_placed_near_named_city(self):
        sid = self.app.addStation('Library', 'Brașov, Romania')
        s = self.app._station(sid)
        self.assertAlmostEqual(s['latitude'], 45.6580)
        self.assertAlmostEqual(s['longitude'], 25.6012)

    def test_v4_migration_retains_counts_and_assigns_real_coordinates(self):
        legacy = {'version': 4, 'stations': [
            {'id': 'FR-001', 'name': 'Central Park', 'location': 'City Center',
             'status': 'Online', 'bins': {'plastic': 52}, 'counts': {'plastic': 700},
             'mapX': 0.73, 'mapY': 0.21},
            {'id': 'FR-009', 'name': 'New Site', 'location': 'Iași, Romania',
             'status': 'Online', 'bins': {}, 'counts': {}}],
            'selectedStationId': 'FR-001', 'nextStationNumber': 10}
        state = normalize_state(legacy)
        self.assertEqual(state['version'], VERSION)
        self.assertEqual(state['stations'][0]['counts']['plastic'], 700)
        self.assertAlmostEqual(state['stations'][0]['latitude'], 44.4268)
        self.assertAlmostEqual(state['stations'][1]['latitude'], 47.1585)
        self.assertAlmostEqual(state['stations'][0]['mapX'], .73)
