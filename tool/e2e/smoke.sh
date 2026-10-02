#!/bin/sh
# Checks the stateful media lab APIs. Requires a freshly restarted lab.
set -eu
exec python3 "$(dirname "$0")/check_api.py" "$@"
