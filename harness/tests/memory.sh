#!/usr/bin/env bash
# Memory Test: STREAM 5.10, 100 M elements per array, 2 threads. Usage: memory.sh OUTPUT_DIR RUN_NUMBER
set -euo pipefail
dir="${1:?output dir}"; run="${2:?run number}"
here="$(cd "$(dirname "$0")" && pwd)"
bin="$here/../.build/stream"
expected_sha=a52bae5e175bea3f7832112af9c085adab47117f7d2ce219165379849231692b
mkdir -p "$dir" "$here/../.build"
if [[ ! -x "$bin" ]]; then
  src="$here/../.build/stream.c"
  curl -fsS -o "$src" https://www.cs.virginia.edu/stream/FTP/Code/stream.c
  echo "$expected_sha  $src" | sha256sum -c -
  gcc -O3 -mcpu=native -fopenmp -DSTREAM_ARRAY_SIZE=100000000 -DNTIMES=20 \
    -mcmodel=large "$src" -o "$bin"
fi
OMP_NUM_THREADS=2 OMP_PROC_BIND=true taskset -c 0,1 "$bin" > "$dir/memory-run${run}.txt" 2>&1
