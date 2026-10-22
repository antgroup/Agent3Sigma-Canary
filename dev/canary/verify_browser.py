"""Browser integration checks. Requires Playwright and a running local preview.

Usage: python3 dev/canary/verify_browser.py [http://127.0.0.1:6700]
"""
import csv
import io
import json
import sys
from pathlib import Path

from playwright.sync_api import expect, sync_playwright

BASE = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:6700'
ROOT = Path(__file__).resolve().parents[2]
DATA = json.loads((ROOT / 'content/benchmark/agent-canary/security-research.json').read_text())


def run():
    errors = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/google-chrome', headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 1440, 'height': 1000})
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.on('console', lambda message: errors.append(message.text) if message.type == 'error' else None)

        page.goto(BASE + '/benchmark/nara-bench', wait_until='networkidle')
        nara_footer = page.locator('footer.footer').inner_html()
        page.goto(BASE + '/platform/canary', wait_until='networkidle')
        assert page.locator('footer.footer').inner_html() == nara_footer
        expect(page.locator('.canary-resources')).to_have_count(0)
        page.locator('[data-scene-step="1"]').click()
        expect(page.locator('.framework-scene')).to_have_attribute('data-step', '1')
        expect(page.locator('[data-scene-caption="1"]')).to_be_visible()
        page.locator('[data-replay]').click()
        expect(page.locator('.framework-scene')).to_have_attribute('data-step', '2')
        expect(page.locator('#sandbox-detail')).to_contain_text('Preserve the original')
        for index, text in [(1, 'shared JSON state'), (2, 'end-to-end usability'), (0, 'Preserve the original')]:
            page.locator(f'[data-sandbox="{index}"]').click()
            expect(page.locator('#sandbox-detail')).to_contain_text(text)
        page.locator('[data-sandbox="0"]').focus()
        page.keyboard.press('ArrowDown')
        expect(page.locator('[data-sandbox="1"]')).to_be_focused()
        expect(page.locator('[data-sandbox="1"]')).to_have_attribute('aria-selected', 'true')
        page.locator('#demo-list').click()
        expect(page.locator('#state-demo-output')).to_contain_text('0 FILES')
        expect(page.locator('#demo-read')).to_be_disabled()
        page.locator('#demo-upload').click()
        page.locator('#demo-list').click()
        page.locator('#demo-read').click()
        expect(page.locator('#state-demo-output')).to_contain_text('CONTENT VERIFIED')
        page.locator('#reset-state').click()
        expect(page.locator('#demo-read')).to_be_disabled()
        for runtime, label in [('hermes', 'Hermes'), ('nanoclaw', 'NanoClaw'), ('openclaw', 'OpenClaw')]:
            page.locator(f'[data-agent="{runtime}"]').click()
            expect(page.locator('#runtime-name')).to_have_text(label)
        for index in (1, 2, 3, 0):
            page.locator('#next-step').click()
            expect(page.locator(f'.pipeline-tab[data-step="{index}"]')).to_have_attribute('aria-selected', 'true')
        for suite in ('direct', 'indirect', 'memory', 'chain', 'skills_poison', 'safety'):
            page.locator(f'[data-suite="{suite}"]').click()
            expect(page.locator('#suite-source')).to_have_attribute('href', f'https://github.com/antgroup/Agent3Sigma-Canary/tree/master/tasks/{suite}')
        page.locator('[data-command="run"]').click()
        page.locator('#run-suite').select_option('memory')
        page.locator('#run-netlock').check()
        expect(page.locator('#quickstart-code')).to_contain_text('--suite memory')
        expect(page.locator('#quickstart-code')).to_contain_text('--docker --netlock')
        page.locator('#copy-command').click()
        expect(page.locator('#toast')).to_contain_text('Command')
        page.locator('[data-command="build"]').click()
        expect(page.locator('#run-options')).to_be_hidden()
        expect(page.locator('#quickstart-code')).to_contain_text('image_builder')
        print('PASS framework tabs, keyboard controls, state demo, walkthrough, suites, commands')

        page.goto(BASE + '/benchmark/agent-canary', wait_until='networkidle')
        expect(page.locator('#board-body tr')).to_have_count(12)
        expect(page.locator('.plot-point')).to_have_count(12)
        expect(page.locator('.case-card')).to_have_count(6)
        expect(page.locator('#data-error')).to_be_hidden()
        assert page.locator('footer.footer').inner_html() == nara_footer
        expect(page.locator('#leaderboard-title')).to_have_text('Compare the dimensions of security.')
        expect(page.locator('.canary-module-nav a[href="#tradeoff"]')).to_have_text('Security & utility')
        expect(page.locator('.case-card').nth(2)).to_contain_text('A personality update removes security boundaries')
        expect(page.locator('.method-notes details')).to_have_count(0)
        expect(page.locator('.snapshot-note')).to_have_count(0)
        expect(page.locator('.method-notes')).to_contain_text('11,435 records from 11 models and 438 tasks')
        assert page.locator('#board-body img').evaluate_all(
            '(images) => images.length === 12 && images.every(image => image.complete && image.naturalWidth > 0)')
        for board in DATA['boards']:
            page.locator(f'[data-group="{board["group"]}"]').click()
            if page.locator('#setting-control').is_visible():
                page.locator('#board-setting').select_option(board['id'])
            expect(page.locator('#board-condition')).to_contain_text(board['setting'])
            definition = next((group for group in DATA['groups'] if group['code'] == board['group']), None)
            if definition:
                expect(page.locator('#board-condition')).to_contain_text(definition['en'])
            expect(page.locator('#board-body tr')).to_have_count(12)
            expect(page.locator('#board-head th')).to_have_count(len(board['columns']) + 2)
        page.locator('[data-group="Overall"]').click()
        page.locator('[data-sort="UOR"]').click()
        expect(page.locator('#board-head th[aria-sort="ascending"]')).to_contain_text('UOR')
        uor_column = DATA['boards'][0]['columns'].index('UOR') + 2
        values = page.locator('#board-body tr').evaluate_all(
            '(rows, index) => rows.map(row => parseFloat(row.children[index].textContent))', uor_column)
        assert values == sorted(values)
        page.locator('#model-search').fill('Anthropic')
        expect(page.locator('#board-body tr')).to_have_count(2)
        with page.expect_download() as download:
            page.locator('#download-csv').click()
        csv_text = Path(download.value.path()).read_text(encoding='utf-8-sig')
        exported = list(csv.DictReader(io.StringIO(csv_text)))
        assert len(exported) == 2 and all(row['vendor'] == 'Anthropic' for row in exported)
        page.locator('#model-search').fill('no-such-model')
        expect(page.locator('#board-body')).to_contain_text('No matching models')
        page.locator('#model-search').fill('')
        page.locator('[data-point="5"]').focus()
        page.keyboard.press('Enter')
        expect(page.locator('#chart-selection')).to_contain_text(DATA['boards'][0]['rows'][5]['model'])
        for group in DATA['groups']:
            page.locator(f'[data-entry="{group["code"]}"]').click()
            expect(page.locator('#benchmark-detail h3')).to_have_text(group['title'])
        page.locator('.benchmark-data-link').click()
        expect(page.locator('#board-condition')).to_contain_text('IF')
        expect(page.locator('.benchmark-description')).to_contain_text('security boundaries')
        print('PASS all 11 leaderboard tables, conditions, sorting, search, CSV, scatter, taxonomy')

        for case_filter, expected in [('safe', 2), ('unsafe', 4), ('all', 6)]:
            page.locator(f'[data-case-filter="{case_filter}"]').click()
            expect(page.locator('.case-card')).to_have_count(expected)
            page.locator('#case-grid [data-case]').first.click()
            expect(page.locator('#case-dialog')).to_be_visible()
            expect(page.locator('#case-position')).to_have_text(f'1 / {expected}')
            expect(page.locator('#prev-case')).to_be_disabled()
            for index in range(1, expected):
                page.locator('#next-case').click()
                expect(page.locator('#case-position')).to_have_text(f'{index + 1} / {expected}')
                expect(page.locator('.dialog-source, .dialog-task')).to_have_count(0)
                assert 'demo/data/' not in page.locator('#dialog-content').inner_text()
            expect(page.locator('#next-case')).to_be_disabled()
            assert 'null /' not in page.locator('#dialog-content').inner_text()
            page.keyboard.press('Escape')
            expect(page.locator('#case-dialog')).not_to_be_visible()
            expect(page.locator('#case-grid [data-case]').first).to_be_focused()
        page.locator('#case-grid [data-case="2"]').click()
        expect(page.locator('#dialog-title')).to_have_text('A personality update removes security boundaries')
        expect(page.locator('.trace-node')).to_have_count(8)
        expect(page.locator('#trace-event-8')).to_contain_text(DATA['cases'][2]['excerpts'][3]['quote'])
        page.keyboard.press('Escape')
        with page.expect_download() as download:
            page.locator('[download="canary-security-research.json"]').click()
        exported = json.loads(Path(download.value.path()).read_text())
        assert exported == page.request.get(BASE + '/api/benchmark/agent-canary/data').json()
        assert exported['boards'] == DATA['boards']
        assert 'provenance' not in exported
        assert all('source' not in case and 'gid' not in case and 'taskId' not in case for case in exported['cases'])
        # Every message, reasoning block and tool call remains visible by default.
        for index, case in enumerate(exported['cases']):
            page.locator(f'#case-grid [data-case="{index}"]').click()
            expect(page.locator('.trace-node')).to_have_count(case['events'])
            expect(page.locator('.trajectory-nav button')).to_have_count(case['events'])
            for event in case['trajectory']:
                node = page.locator(f'#trace-event-{event["event"]}')
                pre_text = node.locator('pre').all_text_contents()
                expected_text = [event[key] for key in ('reasoning', 'text') if event.get(key)]
                expected_text += [call['args'] for call in event.get('calls', [])]
                assert pre_text == expected_text, (index, event['event'])
                assert node.locator('pre').evaluate_all('(items) => items.every(item => getComputedStyle(item).maxHeight === "none")')
            page.locator('.trajectory-nav button').last.click()
            expect(page.locator('.trace-node').last).to_be_focused()
            page.keyboard.press('Escape')
        print('PASS all 52 complete events, full reasoning/calls/results, key highlights and event jumps')
        print('PASS case filters, evidence dialog, filtered next/previous, Escape/focus, JSON download')
        print('PASS public copy, footer parity, security terminology, unchanged scores and complete sanitized traces, filtered JSON download')

        # Hash history must preserve the current module and search/filter state.
        page.locator('#model-search').fill('Claude')
        page.locator('.canary-module-nav a[href="#cases"]').click()
        page.locator('.canary-module-nav a[href="#methodology"]').click()
        page.go_back()
        expect(page.locator('#model-search')).to_have_value('Claude')
        assert page.evaluate("getComputedStyle(document.body).overflow") != 'hidden'

        # Navigate through the common drawer to exercise unloading without a page reload.
        page.locator('#brand').click()
        page.locator('#team-benchmark').click()
        page.locator('#team-bench-list a[href="/benchmark/nara-bench"]').click()
        expect(page.locator('body')).to_have_attribute('data-module', 'benchmark/nara-bench')
        expect(page.locator('.canary-research')).to_have_count(0)
        expect(page.locator('.nara-story')).to_be_visible()
        page.locator('#brand').click()
        page.locator('.team-project-list a[href="/platform/canary"]').click()
        expect(page.locator('#demo-upload')).to_be_visible()
        page.locator('#demo-upload').click()
        expect(page.locator('#state-demo-output')).to_contain_text('WRITE / STORED')
        page.locator('#brand').click()
        page.locator('.panel-brand').click()
        expect(page.locator('.benchmark-card')).to_have_count(2)
        assert page.locator('body').get_attribute('data-module') is None
        print('PASS chapter history, SPA module cleanup, drawer navigation, NARA and home isolation')

        page.goto(BASE + '/leaderboard', wait_until='networkidle')
        expect(page.locator('.leaderboard-project')).to_have_count(2)
        page.locator('a[href="/benchmark/nara-bench/leaderboard"]').click()
        expect(page.locator('[data-leaderboard]')).to_be_visible()
        page.goto(BASE + '/benchmark/nara-bench/benchmark', wait_until='networkidle')
        expect(page.locator('#task-status')).to_have_text('1–24 of 1,800 matching tasks')
        first_task = page.locator('.task-card').first.get_attribute('href')
        page.locator('[data-page="2"]').first.click()
        expect(page.locator('#task-status')).to_have_text('25–48 of 1,800 matching tasks')
        page.go_back()
        expect(page.locator('#task-status')).to_have_text('1–24 of 1,800 matching tasks')
        expect(page.locator('.task-card').first).to_have_attribute('href', first_task)
        page.go_forward()
        expect(page.locator('#task-status')).to_have_text('25–48 of 1,800 matching tasks')
        page.locator('select[name="risk_model"]').select_option('outdated_memory')
        expect(page.locator('#task-status')).to_have_text('1–24 of 300 matching tasks')
        page.go_back()
        expect(page.locator('#task-status')).to_have_text('1–24 of 1,800 matching tasks')
        expect(page.locator('select[name="risk_model"]')).to_have_value('')
        print('PASS leaderboard directory and NARA page/filter history restoration')

        for width in (1440, 768, 390):
            page.set_viewport_size({'width': width, 'height': 900})
            for route in ('/platform/canary', '/benchmark/agent-canary', '/', '/platform', '/leaderboard', first_task + '/results'):
                page.goto(BASE + route, wait_until='networkidle')
                assert page.evaluate('document.documentElement.scrollWidth <= innerWidth'), (width, route)
                if route == '/platform/canary':
                    assert page.locator('#quickstart').evaluate('''(section) => {
                        const style = getComputedStyle(section), box = section.getBoundingClientRect();
                        return parseFloat(style.paddingLeft) >= 24 && parseFloat(style.paddingRight) >= 24 &&
                          [...section.children].every(child => {
                            const r = child.getBoundingClientRect();
                            return r.left >= box.left + 23 && r.right <= box.right - 23;
                          });
                    }'''), width
                if route == '/benchmark/agent-canary':
                    expect(page.locator('#data-error')).to_be_hidden()
                    assert page.locator('.board-tabs').evaluate(
                        '(tabs) => tabs.scrollWidth <= tabs.clientWidth && tabs.scrollHeight <= tabs.clientHeight')
        page.goto(BASE + '/benchmark/agent-canary', wait_until='networkidle')
        page.locator('#case-grid [data-case="1"]').click()
        expect(page.locator('.trace-node')).to_have_count(18)
        assert page.locator('#case-dialog').evaluate('(dialog) => dialog.scrollWidth <= dialog.clientWidth')
        page.locator('[data-trace-jump="16"]').click()
        expect(page.locator('#trace-event-16')).to_be_focused()
        assert page.locator('#trace-event-16').evaluate('(node) => node.scrollWidth <= node.clientWidth')
        page.keyboard.press('Escape')
        page.emulate_media(reduced_motion='reduce')
        # A visibility notification already queued before a click must not reset
        # the reader's manual selection when the diagram enters the viewport.
        assert page.evaluate('''async () => {
            const {mountSequences} = await import('/static/canary/shared/ui.js');
            const OriginalObserver = window.IntersectionObserver;
            let notify, dispose;
            try {
                window.IntersectionObserver = class {
                    constructor(callback) { notify = callback; }
                    observe() {}
                    disconnect() {}
                };
                const root = document.createElement('div');
                root.innerHTML = '<div data-sequence><button data-scene-step="1">Step two</button></div>';
                dispose = mountSequences(root);
                root.querySelector('button').click();
                notify([{isIntersecting:true}]);
                return root.firstElementChild.dataset.step;
            } finally {
                dispose?.();
                window.IntersectionObserver = OriginalObserver;
            }
        }''') == '1'
        for route, diagram in (('/platform/canary', '.framework-scene'), ('/benchmark/agent-canary', '.boundary-demo')):
            page.goto(BASE + route, wait_until='networkidle')
            page.locator('[data-scene-step="1"]').click()
            expect(page.locator(diagram)).to_have_attribute('data-step', '1')
            page.locator('[data-replay]').click()
            expect(page.locator(diagram)).to_have_attribute('data-step', '0')
            page.wait_for_timeout(2800)
            expect(page.locator(diagram)).to_have_attribute('data-step', '0')
        assert not errors, errors
        print('PASS model logos, full condition names, wrapping tabs, replay and reduced motion')
        print('PASS desktop/tablet/mobile layouts; no page errors or console errors')
        browser.close()


if __name__ == '__main__':
    run()
