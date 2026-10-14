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

1. Create the Instance and a `harness/config.env` from `harness/config.example.env`.
2. Copy `harness` to the Instance and install `openssl`, `fio`, `iperf3`, and a C compiler.
3. Run `harness/peer/create.sh harness/config.env` to create the Peer.
4. Run `harness/schedule-sessions.sh 0.05 1 2` on the Instance.
5. Copy the Session directories into `results/`.
6. Run `harness/peer/delete.sh harness/config.env`.
7. Run `python3 report/summarize.py results results/summary.csv`.

## Scope

This project characterizes the Instance. It does not compare the Instance with other systems. SPEC CPU 2017 and HPL are future milestones. The prose follows STE rules but is not certified. See [docs/writing-standard.md](docs/writing-standard.md).
