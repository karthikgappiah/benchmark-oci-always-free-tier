#!/usr/bin/env bash
# Storage Test: fio on an 8 GiB file on /. Usage: storage.sh OUTPUT_DIR RUN_NUMBER
set -euo pipefail
dir="${1:?output dir}"; run="${2:?run number}"
mkdir -p "$dir"
file="${BENCH_FIO_FILE:-$HOME/benchmark-fio.dat}"
trap 'rm -f "$file"' EXIT
common=(--filename="$file" --size=8G --direct=1 --ioengine=libaio --time_based
        --runtime=30 --ramp_time=5 --group_reporting --output-format=json)
fio "${common[@]}" --name=seq-read   --rw=read      --bs=1M --iodepth=16 --output="$dir/fio-seq-read-run${run}.json"
fio "${common[@]}" --name=seq-write  --rw=write     --bs=1M --iodepth=16 --output="$dir/fio-seq-write-run${run}.json"
fio "${common[@]}" --name=rand-read  --rw=randread  --bs=4k --iodepth=32 --output="$dir/fio-rand-read-run${run}.json"
fio "${common[@]}" --name=rand-write --rw=randwrite --bs=4k --iodepth=32 --output="$dir/fio-rand-write-run${run}.json"
