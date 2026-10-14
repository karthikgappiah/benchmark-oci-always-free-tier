#!/usr/bin/env bash
# CPU Test: openssl speed on 1 thread and 2 threads. Usage: cpu.sh OUTPUT_DIR RUN_NUMBER
set -euo pipefail
dir="${1:?output dir}"; run="${2:?run number}"
mkdir -p "$dir"
for threads in 1 2; do
  cpus=$(seq -s, 0 $((threads - 1)))
  for alg in aes-256-gcm sha256; do
    taskset -c "$cpus" openssl speed -seconds 10 -bytes 8192 -multi "$threads" -evp "$alg" \
      > "$dir/cpu-${alg}-t${threads}-run${run}.txt" 2>&1
  done
done
