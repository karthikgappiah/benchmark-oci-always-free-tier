#!/usr/bin/env python3
"""Compute median, minimum, maximum, and relative spread per Test and Session.

Usage: summarize.py RESULTS_DIR OUTPUT_CSV
Run 1 of each Test is the warm-up. It is not used in the statistics.
"""
import csv
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path


def cpu(path):
    value = None
    for line in path.read_text().splitlines():
        m = re.match(r"^\S+\s+([\d.]+)k$", line.strip())
        if m:
            value = float(m.group(1)) / 1e6  # kB/s to GB/s
    return {"throughput": (value, "GB/s")} if value is not None else {}


def memory(path):
    out = {}
    for line in path.read_text().splitlines():
        m = re.match(r"^(Copy|Scale|Add|Triad):\s+([\d.]+)", line)
        if m:
            out[m.group(1).lower()] = (float(m.group(2)) / 1000, "GB/s")
    return out


def fio(path):
    job = json.loads(path.read_text())["jobs"][0]
    side = job["read"] if job["read"]["io_bytes"] else job["write"]
    return {
        "bandwidth": (side["bw"] / 1024, "MiB/s"),
        "iops": (side["iops"], "IOPS"),
        "latency_mean": (side["clat_ns"]["mean"] / 1000, "us"),
    }


def iperf(path):
    end = json.loads(path.read_text())["end"]
    return {
        "throughput": (end["sum_received"]["bits_per_second"] / 1e9, "Gbit/s"),
        "retransmits": (end["sum_sent"].get("retransmits", 0), "count"),
    }


PATTERNS = [
    (re.compile(r"cpu-(.+)-t(\d)-run(\d)\.txt"), lambda m: f"cpu {m[1]} {m[2]}-thread", cpu),
    (re.compile(r"memory-run(\d)\.txt"), lambda m: "memory stream", memory),
    (re.compile(r"fio-(.+)-run(\d)\.json"), lambda m: f"storage {m[1]}", fio),
    (re.compile(r"iperf3-(.+)-run(\d)\.json"), lambda m: f"network {m[1]}", iperf),
]


def main(results_dir, out_csv):
    data = defaultdict(list)  # (session, test, metric, unit) -> [(run, value)]
    for session in sorted(Path(results_dir).glob("*session-*")):
        for path in sorted(session.iterdir()):
            for pattern, name, parse in PATTERNS:
                m = pattern.fullmatch(path.name)
                if not m:
                    continue
                run = int(m.groups()[-1])
                try:
                    metrics = parse(path)
                except (ValueError, KeyError, json.JSONDecodeError):
                    continue
                for metric, (value, unit) in metrics.items():
                    data[(session.name, name(m), metric, unit)].append((run, value))
    with open(out_csv, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["session", "test", "metric", "unit", "runs", "median", "min", "max", "spread_percent"])
        for (session, test, metric, unit), runs in sorted(data.items()):
            values = [v for r, v in runs if r > 1]
            if not values:
                continue
            med = statistics.median(values)
            spread = (max(values) - min(values)) / med * 100 if med else 0.0
            w.writerow([session, test, metric, unit, len(values), f"{med:.3f}",
                        f"{min(values):.3f}", f"{max(values):.3f}", f"{spread:.1f}"])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
