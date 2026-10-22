#!/bin/sh
set -eu

case "${1:-}" in
  backup) printf '%s backup requested\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ;;
  monitor) printf '%s database monitor requested\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ;;
  *) printf 'usage: operations_maintenance.sh {backup|monitor}\n' >&2; exit 2 ;;
esac
