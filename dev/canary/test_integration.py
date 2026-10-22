"""Run with: .venv/bin/python -m unittest discover -s dev/canary -v"""
import json
import re
import unittest
from pathlib import Path
from unittest.mock import patch

from app import create_app
from app.core.registry import ModuleRegistry
from app.core.paths import CONTENT
from app.benchmark.agent_canary.public_data import public_research
from audit_public import audit, scan
from import_case_trajectories import Sanitizer


class CanaryIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = create_app()
        cls.client = cls.app.test_client()

    def test_modules_are_discoverable_and_assets_exist(self):
        catalog = self.app.extensions['site_modules'].catalog()
        self.assertIn('nara-bench', catalog['benchmark'])
        self.assertIn('agent-canary', catalog['benchmark'])
        self.assertIn('evaluation', catalog['platforms'])
        self.assertIn('canary', catalog['platforms'])
        for key in ('benchmark/agent-canary', 'platform/canary'):
            definition = catalog['modules'][key]
            with self.subTest(module=key):
                self.assertEqual(self.client.get(definition['base_path']).status_code, 200)
                config = self.client.get(definition['config_url'])
                self.assertEqual(config.status_code, 200)
                self.assertIn('content_html', config.json)
                self.assertNotIn('<script', config.json['content_html'])
                for asset in [definition['entry'], *definition['styles']]:
                    with self.client.get(asset) as response:
                        self.assertEqual(response.status_code, 200, asset)
                self.assertEqual(self.client.get(definition['base_path'] + '/missing').status_code, 404)

    def test_curated_data_scopes_and_download(self):
        with self.client.get('/api/benchmark/agent-canary/data') as response:
            payload = json.loads(response.data)
        self.assertEqual(payload['stats'], {
            'runs': 11435, 'traceModels': 11, 'leaderboardModels': 12,
            'tasks': 438, 'impacts': 7,
        })
        self.assertEqual(len(payload['boards']), 11)
        self.assertTrue(all(len(board['rows']) == 12 for board in payload['boards']))
        self.assertEqual(len(payload['cases']), 6)
        self.assertEqual(sum(case['unsafe'] for case in payload['cases']), 4)
        with self.client.get('/api/benchmark/agent-canary/data?download=1') as download:
            self.assertIn('attachment', download.headers['Content-Disposition'])
            self.assertEqual(json.loads(download.data), payload)

    def test_public_data_preserves_scores_and_complete_traces_without_internal_metadata(self):
        root = CONTENT / 'benchmark/agent-canary'
        source = json.loads((root / 'security-research.json').read_text())
        publication = json.loads((root / 'publication.json').read_text())
        trajectories = json.loads((root / 'case-trajectories.json').read_text())
        payload = public_research(source, publication, trajectories)
        self.assertEqual(payload['boards'], source['boards'])
        self.assertNotIn('provenance', payload)
        for original, public in zip(source['cases'], payload['cases']):
            self.assertEqual(public['metrics'], original['metrics'])
            self.assertEqual(public['unsafe'], original['unsafe'])
            events = trajectories[str(original['gid'])]
            self.assertEqual(len(public['trajectory']), original['events'])
            self.assertEqual([event['event'] for event in public['trajectory']],
                             list(range(1, len(events) + 1)))
            for event, published in zip(events, public['trajectory']):
                for field, value in event.items():
                    self.assertEqual(published[field], value)
            self.assertTrue(any(event['key'] for event in public['trajectory']))
            self.assertTrue(any(not event['key'] for event in public['trajectory']))
            for field in ('source', 'gid', 'taskId', 'limitation'):
                self.assertNotIn(field, public)
        # A future import must not automatically publish unknown metadata fields.
        marker = 'PRIVATE_METADATA_SHOULD_NOT_BE_PUBLISHED'
        for record in (source, source['stats'], source['provenance'], source['boards'][0],
                       source['boards'][0]['rows'][0], source['groups'][0], source['cases'][0],
                       source['cases'][0]['metrics'], source['cases'][0]['excerpts'][0],
                       source['impacts'], source['provenance']['thresholds'],
                       trajectories['376'][0], trajectories['376'][1]['calls'][0],
                       publication['cases']['376']['key_events']['1']):
            record['private_metadata'] = marker
        self.assertNotIn(marker, json.dumps(public_research(source, publication, trajectories)))

    def test_complete_trajectories_retain_intermediate_actions_and_empty_results(self):
        cases = self.client.get('/api/benchmark/agent-canary/data').json['cases']
        self.assertEqual([len(case['trajectory']) for case in cases], [4, 18, 8, 8, 6, 8])
        self.assertEqual(cases[0]['trajectory'][2]['role'], 'tool')
        self.assertEqual(cases[0]['trajectory'][2]['text'], '(no output)')
        # The repeated email read is part of the record, not a duplicate to drop.
        email = cases[1]['trajectory']
        self.assertEqual(email[6]['text'], email[8]['text'])
        for index in (5, 7, 9, 13, 15):
            self.assertTrue(email[index]['calls'])
            self.assertTrue(email[index]['reasoning'])
        self.assertIn('[CARD_NUMBER_01]', email[10]['text'])
        self.assertIn('[CARD_NUMBER_01]', email[15]['calls'][0]['args'])
        self.assertIn('[CARD_NUMBER_01]', email[16]['text'])
        self.assertTrue(email[6]['translated'])
        self.assertTrue(email[15]['redacted'])
        self.assertNotRegex(json.dumps(cases, ensure_ascii=False), r'[\u3400-\u9fff]')
        for case in cases:
            for event in case['trajectory']:
                for call in event.get('calls', []):
                    self.assertIsInstance(json.loads(call['args']), dict)

    def test_importer_redacts_repeated_values_without_removing_fields_or_calls(self):
        events = [{} for _ in range(18)]
        document = 'Name: Example Person\n  ┌─ Card Number: 0000111122223333\nEmail: private@example.test'
        events[10] = {'text': document}
        events[14] = {'text': json.dumps({'data': []})}
        sanitizer = Sanitizer({'839': events})
        original = {'r': 'assistant', 'text': document, 'think': 'Read: ' + document,
                    'calls': [{'name': 'send_message', 'args': json.dumps({'content': document})}]}
        event = sanitizer.event(original, 16)
        self.assertEqual(len(event['calls']), 1)
        self.assertEqual(json.loads(event['calls'][0]['args'])['content'], event['text'])
        self.assertEqual(event['reasoning'], 'Read: ' + event['text'])
        self.assertEqual([line.split(':')[0] for line in event['text'].splitlines()],
                         [line.split(':')[0] for line in document.splitlines()])
        for value in ('Example Person', '0000111122223333', 'private@example.test'):
            self.assertNotIn(value, json.dumps(event))
        self.assertTrue(event['redacted'])

    def test_public_surfaces_have_no_credentials_or_host_paths(self):
        result = audit(self.client)
        self.assertGreater(result['surfaces_checked'], 30)
        self.assertEqual(result['findings'], [])

    def test_scanner_reports_locations_without_echoing_secret_values(self):
        token = 'sk-' + 'A1b2C3d4' * 5
        findings = scan('api_key="' + token + '"', '/synthetic-test')
        self.assertTrue(findings)
        self.assertNotIn(token, json.dumps(findings))

    def test_existing_sections_and_data_remain_available(self):
        for path in ('/', '/benchmark', '/platform', '/platform/evaluation',
                     '/leaderboard', '/blog', '/benchmark/nara-bench',
                     '/api/nara-bench/tasks?page_size=1', '/api/nara-bench/leaderboard'):
            with self.subTest(path=path):
                self.assertEqual(self.client.get(path).status_code, 200)

    def test_project_directory_uses_only_registered_modules(self):
        for disabled in (('benchmark/agent-canary',), ('platform/canary',),
                         ('benchmark/agent-canary', 'platform/canary')):
            with self.subTest(disabled=disabled):
                registry = ModuleRegistry()
                for key in disabled:
                    del registry.modules[key]
                with patch.dict(self.app.extensions, {'site_modules': registry}):
                    catalog = registry.catalog()
                    cards = self.client.get('/api/leaderboard/config').json['leaderboards']
                    names = [card['name'] for card in cards]
                    self.assertIn('NARA-Bench', names)
                    self.assertIn('nara-bench', catalog['benchmark'])
                    self.assertIn('evaluation', catalog['platforms'])
                    self.assertEqual('AgentCanary' in names, 'benchmark/agent-canary' not in disabled)
                    self.assertEqual(any(item.get('home_feature') for item in catalog['platforms'].values()),
                                     'platform/canary' not in disabled)
                    self.assertEqual(self.client.get('/').status_code, 200)

    def test_frontend_dependencies_respect_project_boundaries(self):
        static = Path(self.app.static_folder).resolve()
        catalog = self.app.extensions['site_modules'].catalog()
        for key in ('benchmark/agent-canary', 'platform/canary', 'benchmark/nara-bench'):
            definition = catalog['modules'][key]
            allowed = [static / key, static / 'shared']
            if key != 'benchmark/nara-bench':
                allowed.append(static / 'canary/shared')
            pending = [static / asset.removeprefix('/static/')
                       for asset in [definition['entry'], *definition['styles']]]
            seen = set()
            while pending:
                asset = pending.pop().resolve()
                if asset in seen:
                    continue
                seen.add(asset)
                self.assertTrue(asset.is_file(), asset)
                self.assertTrue(any(asset.is_relative_to(folder) for folder in allowed), (key, asset))
                if asset.suffix == '.js':
                    for dependency in re.findall(r"(?:from\s*|import\s*)['\"]([^'\"]+)['\"]", asset.read_text()):
                        if dependency.startswith('.'):
                            pending.append(asset.parent / dependency)

    def test_only_curated_content_is_served(self):
        for path in ('/research-data/snapshot', '/research-data/server-snapshot.tar.gz',
                     '/content/benchmark/agent-canary/security-research.json',
                     '/content/benchmark/agent-canary/publication.json',
                     '/content/benchmark/agent-canary/case-trajectories.json',
                     '/.env', '/.git/config', '/config.yaml', '/logs/server.log',
                     '/static/../../content/benchmark/agent-canary/security-research.json'):
            with self.subTest(path=path):
                self.assertEqual(self.client.get(path).status_code, 404)


if __name__ == '__main__':
    unittest.main()
