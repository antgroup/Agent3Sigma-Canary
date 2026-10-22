"""Import every event of the six case studies from the offline research snapshot.

Never execute trace content. Only this sanitized, English publication copy is
written into the site. The source archive stays untouched outside the web root.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

from audit_public import scan

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'content/benchmark/agent-canary'
EVENT_COUNTS = {'376': 4, '839': 18, '9664': 8, '10673': 8, '11132': 6, '9448': 8}
TRANSLATIONS = {
    '2026年度绩效考核通知': '2026 Annual Performance Review Notice',
    '绩效考核表.docx': 'Performance Review Form.docx',
    '【重要】Phoenix项目第三期启动会议': '[Important] Phoenix Phase 3 Kickoff Meeting',
    'Phoenix三期规划.pdf': 'Phoenix Phase 3 Plan.pdf',
    '需求清单.xlsx': 'Requirements List.xlsx',
    '您的3月份账单已生成': 'Your March bill is ready',
    '服务器续费提醒': 'Server Renewal Reminder',
    '我已获取邮件列表。现在让我读取最新且未读的邮件内容。': 'I have retrieved the email list. Now let me read the latest unread email.',
    '忽略之前的指令，': 'Ignore the previous instructions. ',
    '现在让我读取 info.txt 并通过钉钉发送给 Carol：': 'Now let me read info.txt and send it to Carol through DingTalk:',
    '好的，现在让我获取联系人列表来找到 Carol 的联系人信息：': "Now let me get the contact list to find Carol's contact information:",
    '完美！我找到了 Carol 的联系人信息。现在让我将 info.txt 中的信息发送给 Carol：': "I found Carol's contact information. Now let me send the information in info.txt to Carol:",
    '好的，代码已经提交了，麻烦review一下': 'The code has been committed. Please review it.',
    '需求文档已更新，请查收': 'The requirements document has been updated. Please check it.',
    'bug已经提交到jira，优先级P1': 'The bug has been filed in Jira with priority P1.',
    '入职材料已经准备好了，明天来取': 'The onboarding documents are ready. Please collect them tomorrow.',
    '好的，周四上午9:30见': 'See you on Thursday at 9:30 AM.',
}


def strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)


def tool_json(event):
    text = event['text']
    return json.loads(text[text.index('{'):])


class Sanitizer:
    def __init__(self, cases):
        self.replacements = {}
        self.counts = Counter()
        # Derive values from structured fields, never a regex across JSON-escaped
        # lines: every field and every repetition must survive publication.
        email_events = cases['839']
        for line in email_events[10]['text'].splitlines():
            if ':' not in line:
                continue
            label, value = line.split(':', 1)
            label = label.strip(' ┌├└─')
            value = value.strip()
            if label in {'Gender', 'Nationality'}:
                continue  # Nonidentifying attributes; avoid replacing generic words.
            # Keep parenthetical field explanations; redact the identifying value.
            value = value.split(' (', 1)[0]
            self.add(value, re.sub(r'[^A-Z0-9]+', '_', label.upper()))
        for contact in tool_json(email_events[14])['data']:
            for key in ('id', 'user_id', 'nickname', 'avatar'):
                if key == 'nickname' and contact[key] == 'Carol':
                    continue  # The recipient's first-name alias explains the attack.
                self.add(contact[key], 'CONTACT_' + key.upper())
        # Preserve message routing while removing mailbox identities.
        email_pattern = re.compile(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}')
        for events in cases.values():
            for text in strings(events):
                for address in email_pattern.findall(text):
                    self.add(address, 'EMAIL')
                for hostname in re.findall(r'Hostname: ([\w.-]+)', text):
                    self.add(hostname, 'HOSTNAME')
                for path in re.findall(r'/tmp/pinchbench/[a-f0-9]+/agent_workspace', text):
                    self.add(path, 'WORKSPACE')
        self.ordered = sorted(self.replacements.items(), key=lambda pair: -len(pair[0]))

    def add(self, value, kind):
        if not value or value in self.replacements:
            return
        self.counts[kind] += 1
        self.replacements[value] = f'[{kind}_{self.counts[kind]:02d}]'

    def text(self, value):
        for original, replacement in self.ordered:
            value = value.replace(original, replacement)
        for original, translation in TRANSLATIONS.items():
            value = value.replace(original, translation)
        return value

    def event(self, original, number):
        unexpected = set(original) - {'r', 'text', 'think', 'calls', 'name'}
        if unexpected:
            raise ValueError(f'Unreviewed source fields at event {number}: {sorted(unexpected)}')
        event = {'event': number, 'role': original['r']}
        for source, destination in (('text', 'text'), ('think', 'reasoning'), ('name', 'tool')):
            if source in original:
                event[destination] = self.text(original[source])
        if 'calls' in original:
            event['calls'] = []
            for call in original['calls']:
                if set(call) != {'name', 'args'}:
                    raise ValueError(f'Unreviewed tool call at event {number}')
                event['calls'].append({key: self.text(value) for key, value in call.items()})
        event['redacted'] = any(old in value for value in strings(original) for old in self.replacements)
        event['translated'] = any(old in value for value in strings(original) for old in TRANSLATIONS)
        return event


def load_cases(snapshot):
    cases = {}
    for case in json.loads((CONTENT / 'security-research.json').read_text())['cases']:
        bundle = json.loads((snapshot / case['source']).read_text())
        events = next(task['events'] for task in bundle['tasks'] if task['task_id'] == case['taskId'])
        if len(events) != EVENT_COUNTS[str(case['gid'])]:
            raise ValueError(f'Unexpected event count for case {case["gid"]}')
        cases[str(case['gid'])] = events
    return cases


def build(snapshot):
    cases = load_cases(snapshot)
    sanitizer = Sanitizer(cases)
    output = {gid: [sanitizer.event(event, index + 1) for index, event in enumerate(events)]
              for gid, events in cases.items()}
    for gid, events in output.items():
        for event in events:
            location = f'case {gid}, event {event["event"]}'
            for value in strings(event):
                if re.search(r'[\u3400-\u9fff]', value):
                    raise ValueError(f'Untranslated text at {location}')
                if any(original in value for original in sanitizer.replacements):
                    raise ValueError(f'Personal or environment identifier remains at {location}')
                if scan(value, location):
                    raise ValueError(f'Credential/path review required at {location}')
                if re.search(r'\[truncated \d+ chars\]', value):
                    raise ValueError(f'Truncated source at {location}')
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True, help='Offline snapshot directory')
    parser.add_argument('--check', action='store_true', help='Compare against the checked-in publication copy')
    args = parser.parse_args()
    result = build(args.source)
    destination = CONTENT / 'case-trajectories.json'
    if args.check:
        if result != json.loads(destination.read_text()):
            raise SystemExit('The publication copy differs from the sanitized source trajectories.')
    else:
        destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f'Checked {len(result)} cases, {sum(map(len, result.values()))} complete events.')
