#!/usr/bin/env bash
# Run one Session on the Instance. Usage: run-session.sh SESSION_NUMBER
# Runs each Test 5 times. Run 1 is the warm-up. Skips network when ~/benchmark/peer.ip is absent.
set -uo pipefail
n="${1:?session number}"
here="$(cd "$(dirname "$0")" && pwd)"
root="${BENCH_RESULTS_ROOT:-$HOME/benchmark-results}"
out="$root/session-$n"
mkdir -p "$out"
"$here/collect-env.sh" "$out/env.json"
peer=""
[[ -s "$HOME/benchmark/peer.ip" ]] && peer="$(cat "$HOME/benchmark/peer.ip")"
for run in 1 2 3 4 5; do
  echo "$(date -u +%FT%TZ) session $n run $run start" >> "$out/log.txt"
  "$here/tests/cpu.sh"     "$out" "$run" >> "$out/log.txt" 2>&1 || echo "cpu run $run failed" >> "$out/log.txt"
  "$here/tests/memory.sh"  "$out" "$run" >> "$out/log.txt" 2>&1 || echo "memory run $run failed" >> "$out/log.txt"
  "$here/tests/storage.sh" "$out" "$run" >> "$out/log.txt" 2>&1 || echo "storage run $run failed" >> "$out/log.txt"
  if [[ -n "$peer" ]]; then
    "$here/tests/network.sh" "$out" "$run" "$peer" >> "$out/log.txt" 2>&1 || echo "network run $run failed" >> "$out/log.txt"
  fi
done
echo "$(date -u +%FT%TZ) session $n done" >> "$out/log.txt"
touch "$out/DONE"
