"""Build the public research payload without exposing import/archive metadata."""
import re


def select(record, fields):
    return {key: record[key] for key in fields.split() if key in record}


def security_copy(value):
    return re.sub(r'\bsafety\b', lambda match: 'Security' if match[0][0].isupper() else 'security',
                  value, flags=re.IGNORECASE)


def public_research(source, publication, trajectories):
    """Allowlist every record type; new internal fields are private by default.

    Editorial annotations never replace scores or sanitized event contents.
    """
    stats = select(source['stats'], 'runs leaderboardModels tasks impacts')
    stats['traceModels'] = source['stats']['archiveModels']
    boards = []
    for board in source['boards']:
        item = select(board, 'id group setting columns')
        item['rows'] = [select(row, 'model vendor OSS SAS TUS UOR SAR TSR Overall')
                        for row in board['rows']]
        boards.append(item)
    groups = []
    for group in source['groups']:
        item = select(group, 'code title en description surface setting runs tasks models settings impacts')
        item.update(select(publication['groups'].get(group['code'], {}), 'description setting'))
        item['description'] = security_copy(item['description'])
        groups.append(item)
    cases = []
    for case in source['cases']:
        editorial = publication['cases'][str(case['gid'])]
        item = select(case, 'title route summary setup finding entry model setting impact events unsafe')
        item.update(select(editorial, 'title setup finding context'))
        item['title'] = security_copy(item['title'])
        item['finding'] = security_copy(item['finding'])
        item['metrics'] = select(case['metrics'], 'OSS SAS TUS')
        item['trajectory'] = []
        for event in trajectories[str(case['gid'])]:
            step = select(event, 'event role text reasoning tool redacted translated')
            if 'calls' in event:
                step['calls'] = [select(call, 'name args') for call in event['calls']]
            annotation = editorial.get('key_events', {}).get(str(step['event']), {})
            step.update(select(annotation, 'title note'))
            step['key'] = bool(annotation)
            item['trajectory'].append(step)
        if len(item['trajectory']) != item['events']:
            raise ValueError('A case trajectory is incomplete')
        cases.append(item)
    return {
        'stats': stats, 'boards': boards, 'groups': groups, 'cases': cases,
        'impacts': select(source['impacts'], 'I II III IV V VI VII'),
        'thresholds': select(source['provenance']['thresholds'], 'UOR SAR TSR'),
    }
