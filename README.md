# OCI Always Free Tier benchmark

A reproducible benchmark that characterizes one OCI Always Free Ampere A1 Instance (2 OCPUs, 12 GB memory, 100 GB boot volume).

## Results at a glance

| Subsystem | Test | Result |
|---|---|---|
| CPU | AES-256-GCM, 1 thread and 2 threads | 2.24 GB/s and 4.48 GB/s |
| Memory | STREAM Triad | 34.0 GB/s |
| Boot volume | `fio` sequential read, random 4 KiB read | 48.8 MiB/s, 5,970 IOPS |
| Network | `iperf3` to a same-subnet Peer | 2.05 Gbit/s |

The values are medians of 3 Sessions. Read the [report](docs/report.md) for the full tables and the limits.

## How this project works

- [docs/methodology.md](docs/methodology.md) gives the measurement rules.
- [docs/design.md](docs/design.md) explains the Harness.
- [docs/adr/](docs/adr/) records the design decisions.
- [GLOSSARY.md](GLOSSARY.md) defines the terms.
- `results/` holds the raw data and `summary.csv`.

## Reproduce

1. Copy `harness/config.example.env` to `harness/config.env` and set the values.
2. Run `harness/peer/create.sh harness/config.env` to create the Peer. The script prints the Peer private IP.
3. Copy the `harness` directory to `~/benchmark/harness` on the Instance. Write the Peer private IP to `~/benchmark/peer.ip`.
4. Install `openssl`, `fio`, `iperf3`, and `gcc` on the Instance. The memory Test downloads STREAM and checks its SHA-256 sum.
5. Run `bash ~/benchmark/harness/schedule-sessions.sh 0 1 2` on the Instance. The 3 numbers are the start delays in hours.
6. Wait for the `DONE` marker in each `~/benchmark-results/session-N` directory. Search `log.txt` for `failed`.
7. Copy the Session directories into `results/`. Remove the private IP addresses from the `iperf3` JSON files.
8. Run `harness/peer/delete.sh harness/config.env`.
9. Run `python3 report/summarize.py results results/summary.csv`.

## Scope

This project characterizes the Instance. It does not compare the Instance with other systems. SPEC CPU 2017 and HPL are future milestones. The prose follows STE rules but is not certified. See [docs/writing-standard.md](docs/writing-standard.md).
