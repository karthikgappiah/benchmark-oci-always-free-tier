#!/usr/bin/env bash
# Schedule Sessions on the Instance with transient systemd timers.
# Usage: schedule-sessions.sh DELAY_HOURS_1 DELAY_HOURS_2 DELAY_HOURS_3
# Run through /bin/bash: SELinux blocks systemd from executing files in the home directory.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
n=1
for delay in "$@"; do
  sudo systemd-run --unit="bench-session-$n" --uid="$(id -u)" --gid="$(id -g)" \
    --on-active="${delay}h" --property=Environment=HOME="$HOME" \
    /bin/bash "$here/run-session.sh" "$n"
  n=$((n + 1))
done
