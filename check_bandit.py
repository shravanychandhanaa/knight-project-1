import json
import sys


def main(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    findings = data.get('results', [])
    critical = 0
    high = 0
    for r in findings:
        sev = r.get('issue_severity', '').upper()
        if sev == 'CRITICAL':
            critical += 1
        if sev == 'HIGH':
            high += 1

    print(f'Bandit findings: CRITICAL={critical}, HIGH={high}')
    if critical > 0 or high > 0:
        print('Failing due to HIGH/CRITICAL Bandit findings')
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python check_bandit.py <bandit_report.json>')
        sys.exit(2)
    main(sys.argv[1])
