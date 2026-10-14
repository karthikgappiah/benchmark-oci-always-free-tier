# Report: OCI Always Free Ampere A1 Instance

This report gives the performance of one OCI Always Free Ampere A1 Instance. It covers CPU, memory, boot volume, and network. The method is in [methodology.md](methodology.md). Raw data is in `results/`. Terms are defined in [GLOSSARY.md](../GLOSSARY.md).

## Summary

- The Instance gives stable results. The median of each Test differs by less than 1.5 % between the 3 Sessions.
- CPU throughput scales in a linear way from 1 thread to 2 threads.
- Memory bandwidth is about 34 GB/s (STREAM Triad).
- Boot volume throughput is about 49 MiB/s, and random 4 KiB IOPS is about 5,970. The values do not change between Runs. This suggests a limit in the volume.
- Network throughput is about 2.05 Gbit/s, close to the 2 Gbps Baseline. Retransmits are high.

## Setup

| Item | Value |
|---|---|
| Shape | `VM.Standard.A1.Flex`, 2 OCPUs, 12 GB provisioned memory |
| Processor | Neoverse-N1, 1 thread per core, KVM guest |
| Operating system | Oracle Linux Server 9.8, kernel `6.12.0-206.104.4.4.el9uek.aarch64` |
| Boot volume | 100 GB (`/` has 30 GB of file system space) |
| Region | us-sanjose-1 |

Each Session wrote `env.json` with the full details.

### Provisioned and visible memory

The shape has 12 GB of provisioned memory. The guest shows `MemTotal` of 11,159,744 kB (about 10.6 GiB). This report does not state a cause for the difference. The cause was not verified.

## Method in brief

- 3 Sessions started about 1 hour apart in one evening.
- Each Session ran every Test 5 times. Run 1 is a warm-up and is not used.
- The tables give the median of Runs 2 to 5. The spread is (maximum - minimum) / median.
- The network Tests used a temporary Peer in the same subnet. The harness deleted the Peer afterwards.

## Results

### CPU (`openssl speed`)

| Test | Session 1 | Session 2 | Session 3 | Unit |
|---|---|---|---|---|
| AES-256-GCM, 1 thread | 2.239 | 2.248 | 2.242 | GB/s |
| AES-256-GCM, 2 threads | 4.479 | 4.484 | 4.475 | GB/s |
| SHA-256, 1 thread | 1.820 | 1.820 | 1.820 | GB/s |
| SHA-256, 2 threads | 3.644 | 3.592 | 3.642 | GB/s |

The 2-thread result is about 2 times the 1-thread result. Two cases show a spread of 3.9 % and 4.5 %. See Limits.

### Memory (STREAM, 100 M elements)

| Kernel | Session 1 | Session 2 | Session 3 | Unit |
|---|---|---|---|---|
| Copy | 37.91 | 37.81 | 37.60 | GB/s |
| Scale | 39.26 | 39.36 | 39.33 | GB/s |
| Add | 34.00 | 33.91 | 33.93 | GB/s |
| Triad | 34.03 | 33.99 | 34.02 | GB/s |

### Boot volume (`fio`, 8 GiB file on `/`)

| Test | Session 1 | Session 2 | Session 3 | Unit |
|---|---|---|---|---|
| Sequential read | 48.82 | 48.82 | 48.82 | MiB/s |
| Sequential write | 48.81 | 48.82 | 48.82 | MiB/s |
| Random 4 KiB read | 5,972 | 5,971 | 5,971 | IOPS |
| Random 4 KiB write | 5,962 | 5,963 | 5,962 | IOPS |

The spread is 1.1 % or less. A value that stays this constant suggests a throughput and IOPS limit in the boot volume.

### Network (`iperf3`, 30 s Runs, to the Peer)

| Test | Session 1 | Session 2 | Session 3 | Unit |
|---|---|---|---|---|
| Forward, 1 stream | 2.050 | 2.049 | 2.050 | Gbit/s |
| Reverse, 1 stream | 2.053 | 2.053 | 2.053 | Gbit/s |
| Forward, 4 streams | 2.047 | 2.041 | 2.049 | Gbit/s |

Retransmits were about 10,500 to 11,100 for each Run with 1 stream. With 4 streams the median was 1,480 to 1,840 and the spread was large. The throughput stays close to the 2 Gbps Baseline. This is consistent with a rate limit that drops packets. The repository did not verify this cause.

## Limits

- The result applies to one Instance, one region, and one evening.
- The 3 Sessions ran about 1 hour apart. They do not show variation between days or between physical hosts.
- Some Runs show a larger spread than the others: 2-thread AES-256-GCM in Session 3 (4.5 %), 2-thread SHA-256 in Session 2 (3.9 %), and 1-stream forward `iperf3` in Session 2 (25 %). The report does not state a cause.
- A virtual machine hides CPU frequency and hardware settings.
- The Peer shares the free quota and the subnet. The network result is a result to that Peer.
- SPEC CPU 2017 and HPL are not in this milestone. See [ADR 0003](adr/0003-no-spec-cpu-2017-in-repository.md).
