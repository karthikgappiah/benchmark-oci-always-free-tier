# Harness design

This document explains how the Harness is built and why. For the measurement rules, see [methodology.md](methodology.md). Terms are defined in [GLOSSARY.md](../GLOSSARY.md).

## Design goals

| Goal | How the design meets it |
|---|---|
| Reproducible | One script starts a Session. Each Test records the tool version and the exact command line. |
| Honest | Every Run is stored as a raw file. The summary is computed from raw files only. |
| Low disturbance | Sessions start from timers on the Instance. No SSH connection is open during a Run. |
| Safe | No secret or IP address is stored in the repository. Peer resources have a tag and are deleted after use. |

## Components

| Path | Role |
|---|---|
| `harness/config.example.env` | Template for the settings that the Peer scripts need. The real file is not committed. |
| `harness/collect-env.sh` | Writes `env.json` with the kernel, CPU, memory, shape, and tool versions. |
| `harness/tests/{cpu,memory,storage,network}.sh` | One script for each Subsystem. Each script runs one Run of each Test and writes raw output. |
| `harness/run-session.sh` | Runs 5 Runs of every Test in order and writes the `DONE` marker. |
| `harness/schedule-sessions.sh` | Creates one transient `systemd` timer for each Session. |
| `harness/peer/create.sh`, `harness/peer/delete.sh` | Create and delete the temporary Peer with the OCI CLI. |
| `report/summarize.py` | Reads raw files and writes `summary.csv`. |

## Data flow

1. `schedule-sessions.sh` creates a timer for each Session.
2. The timer starts `run-session.sh`.
3. `run-session.sh` calls `collect-env.sh`, then the 4 Test scripts, 5 times.
4. Raw files go to `~/benchmark-results/session-N` on the Instance.
5. The operator copies the directory into `results/` in the repository.
6. `summarize.py` excludes Run 1 and writes the median, minimum, maximum, and spread for each metric.

## Decisions that are not obvious

- **Timers, not SSH.** A Session takes about 40 minutes. A dropped connection must not stop it. A timer also keeps the operator's workstation out of the measurement.
- **Run through `/bin/bash`.** SELinux on Oracle Linux 9 blocks `systemd` from executing a file in a home directory. The timer runs `/bin/bash script` instead. This failure was found on the first scheduled Session.
- **Pin threads with `taskset`.** Pinning removes scheduler placement as a source of variation.
- **Exclude Run 1.** The first Run warms caches and the file system. It is stored but not used.
- **Peer for the network.** A test on the loopback interface does not use the network. See [ADR 0002](adr/0002-temporary-same-subnet-peer.md).
- **Raw data in Git.** A reader can recompute every number in the report.

## Failure handling

- A failed Test writes `<test> run N failed` to `log.txt`. The Session continues with the next Test.
- The Session writes the `DONE` marker at the end, also after a failed Run. Search `log.txt` for `failed` before you use a Session.
- The network Tests run only when `~/benchmark/peer.ip` exists on the Instance.
- `peer/delete.sh` lists resources with the Peer tag after deletion. An empty list shows that no resource remains.
