# Methodology

This document explains how the benchmark measures the Instance. Terms are defined in [GLOSSARY.md](../GLOSSARY.md).

## Goal

The benchmark characterizes the performance of one OCI Always Free Ampere A1 Instance (see [ADR 0001](adr/0001-characterize-only.md)).

## Instance under test

| Item | Value |
|---|---|
| Shape | `VM.Standard.A1.Flex`, 2 OCPUs, 12 GB memory, 2 Gbps network cap |
| Processor | Neoverse-N1, 1 thread per core |
| Operating system | Oracle Linux 9 |
| Boot volume | 100 GB |
| Hypervisor | KVM (guest) |

## Subsystems and Tests

| Subsystem | Tool | Property measured |
|---|---|---|
| CPU | `openssl speed` | Single-thread and 2-thread cryptographic throughput |
| Memory | STREAM | Copy, Scale, Add, and Triad bandwidth |
| Boot volume | `fio` | Sequential and random read and write throughput, IOPS, latency |
| Network | `iperf3` | TCP throughput and retransmits to the Peer |

Each Test records the tool version and the exact command line.

## Rules

1. **Baseline first.** Compare each result with the Oracle shape specification. No other system is used.
2. **Record everything.** Each Session writes `env.json` with the kernel, CPU, memory, shape configuration, and tool versions.
3. **Change one thing at a time.** One Session changes no setting of the Instance.
4. **Repeat and report the spread.** Each Test has 5 Runs in each Session. The first Run is a warm-up and is stored but not used. The report gives the median, minimum, maximum, and relative spread of the 4 remaining Runs.
5. **Compare like with like.** All Sessions use the same tool versions, flags, and Instance.
6. **Report clearly.** The report gives the setup, the method, the results, and the limits.

## Adaptations for a virtual machine

- The guest has no `cpufreq` interface. The report records that the CPU frequency is not visible.
- `dmidecode` shows virtual SMBIOS data only. The report does not make a statement on BIOS or DIMM settings.
- Benchmark threads are pinned with `taskset`.
- Visible memory is lower than provisioned memory. The report shows both values and does not state a cause that was not verified.

## Test conditions

- The storage Test uses an 8 GiB file on `/`. The harness deletes the file after each Run.
- STREAM array size is at least 4 times the cache size that the guest reports.
- The Instance runs no other workload during a Session.

## Sessions

The measurement has 3 Sessions that start about 1 hour apart in one evening. The Sessions start from timers on the Instance. This schedule does not separate variation between days. Shared physical hosts can change the result over a longer time. The report states this limit.

## Network Peer

The Peer is a temporary instance in the same subnet. See [ADR 0002](adr/0002-temporary-same-subnet-peer.md).

## Known limits

- The result applies to one Instance, one region, and one time window.
- A virtual machine hides some hardware details.
- SPEC CPU 2017 is not part of the first milestone. See [ADR 0003](adr/0003-no-spec-cpu-2017-in-repository.md).
