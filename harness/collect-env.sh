#!/usr/bin/env bash
# Write a JSON description of the Instance environment to the path in $1.
set -euo pipefail
out="${1:?usage: collect-env.sh OUTPUT_FILE}"
python3 - "$out" <<'PY'
import json, os, platform, subprocess, sys, urllib.request

def sh(cmd):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30).stdout.strip()
    except Exception as exc:
        return f"error: {exc}"

meta = {}
try:
    req = urllib.request.Request("http://169.254.169.254/opc/v2/instance/",
                                 headers={"Authorization": "Bearer Oracle"})
    d = json.load(urllib.request.urlopen(req, timeout=5))
    meta = {k: d.get(k) for k in ("shape", "shapeConfig", "canonicalRegionName", "availabilityDomain")}
except Exception as exc:
    meta = {"error": str(exc)}

env = {
    "collected_utc": sh("date -u +%Y-%m-%dT%H:%M:%SZ"),
    "kernel": platform.release(),
    "os_release": sh("cat /etc/oracle-release"),
    "virtualization": sh("systemd-detect-virt"),
    "lscpu": sh("lscpu"),
    "numa": sh("numactl --hardware 2>&1 | head -5"),
    "meminfo_total_kb": sh("awk '/MemTotal/ {print $2}' /proc/meminfo"),
    "cpufreq_interface_present": os.path.isdir("/sys/devices/system/cpu/cpu0/cpufreq"),
    "block_devices": sh("lsblk -o NAME,SIZE,TYPE,MOUNTPOINT"),
    "root_filesystem": sh("df -h / | tail -1"),
    "tool_versions": {
        "openssl": sh("openssl version"),
        "fio": sh("fio --version 2>&1"),
        "gcc": sh("gcc --version | head -1"),
        "iperf3": sh("iperf3 --version 2>&1 | head -1"),
    },
    "instance_metadata": meta,
}
with open(sys.argv[1], "w") as fh:
    json.dump(env, fh, indent=2)
PY
