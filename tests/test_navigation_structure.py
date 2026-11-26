"""Static checks for the eight-tab organization, not a GUI rendering test."""
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class NavigationStructureTests(unittest.TestCase):
    def test_sidebar_has_eight_entries(self):
        main = (ROOT / 'main.qml').read_text(encoding='utf-8')
        labels = re.findall(r'NavItem\s*\{\s*label:\s*"([^"]+)"', main)
        self.assertEqual(labels, [
            'Overview', 'Stations', 'Collections', 'Alerts', 'Maintenance',
            'Analytics & Reports', 'AI Detection', 'Settings',
        ])

    def test_all_subscreens_present(self):
        for workspace, screens in {
            'StationsWorkspace.qml': ['StationsPage', 'MapPage', 'ForecastsPage'],
            'CollectionsWorkspace.qml': ['CollectionsPage', 'CalendarPage'],
            'InsightsWorkspace.qml': ['AnalyticsPage', 'ReportsPage', 'ActivityPage'],
        }.items():
            text = (ROOT / workspace).read_text(encoding='utf-8')
            for screen in screens:
                self.assertIn(screen + ' {', text)
            self.assertIn('WorkspaceTabs {', text)

    def test_deep_links_and_calendar_direct_request(self):
        main = (ROOT / 'main.qml').read_text(encoding='utf-8')
        for name in ['goToStation', 'requestCollection', 'requestMaintenance',
                     'goToCalendar', 'goToAnalytics', 'goToActivity']:
            self.assertIn('function ' + name + '(', main)
        calendar = (ROOT / 'CalendarPage.qml').read_text(encoding='utf-8')
        self.assertIn('backend.requestCollection(', calendar)
        self.assertIn('backend.scheduleCollection(', calendar)


if __name__ == '__main__':
    unittest.main()
