"""Shared starter data and personal save behavior."""
import json
import tempfile
import unittest
from pathlib import Path

from backend import Backend, VERSION, load_demo_seed


class SharedDemoSeedTests(unittest.TestCase):
    def test_seed_contains_complete_fictional_state(self):
        data = load_demo_seed()
        self.assertEqual(data['version'], VERSION)
        self.assertGreaterEqual(len(data['stations']), 3)
        self.assertIsInstance(data['collections'], list)
        self.assertIsInstance(data['tickets'], list)

    def test_initial_seed_local_edits_and_restore(self):
        with tempfile.TemporaryDirectory() as dirname:
            path = Path(dirname) / 'state.json'
            initial = Backend(data_file=path)
            self.assertTrue(path.exists())
            expected_stations = len(load_demo_seed()['stations'])
            self.assertEqual(len(initial.state['stations']), expected_stations)

            extra = initial.addStation('Extra Demo Site', 'Bucharest, Romania')
            self.assertTrue(extra)
            reloaded = Backend(data_file=path)
            self.assertEqual(len(reloaded.state['stations']), expected_stations + 1)

            reloaded.restoreDemo()
            self.assertEqual(len(reloaded.state['stations']), expected_stations)
            self.assertEqual(json.loads(path.read_text(encoding='utf-8'))['version'], VERSION)


if __name__ == '__main__':
    unittest.main()
