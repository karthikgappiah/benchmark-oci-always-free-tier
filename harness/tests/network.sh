#!/usr/bin/env bash
# Network Test: iperf3 to the Peer. Usage: network.sh OUTPUT_DIR RUN_NUMBER PEER_PRIVATE_IP
set -euo pipefail
dir="${1:?output dir}"; run="${2:?run number}"; peer="${3:?peer ip}"
mkdir -p "$dir"
iperf3 -c "$peer" -t 30 -P 1 -J > "$dir/iperf3-fwd-p1-run${run}.json"
iperf3 -c "$peer" -t 30 -P 1 -R -J > "$dir/iperf3-rev-p1-run${run}.json"
iperf3 -c "$peer" -t 30 -P 4 -J > "$dir/iperf3-fwd-p4-run${run}.json"
