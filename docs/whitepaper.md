# Whitepaper: Characterizing an OCI Always Free Ampere A1 Instance

This whitepaper describes a reproducible benchmark of one Oracle Cloud Infrastructure (OCI) Always Free Ampere A1 Instance. It gives the method, the commands, the results, and the meaning of the results. Terms are defined in [GLOSSARY.md](../GLOSSARY.md). The writing follows the rules of ASD-STE100 but is not certified (see [writing-standard.md](writing-standard.md)).

## 1. Abstract

The Always Free tier gives a 4-OCPU, 24 GB Ampere A1 allowance at no cost. This benchmark measures one Instance of that allowance (2 OCPUs, 12 GB, 100 GB boot volume). It measures CPU, memory, boot volume, and network. The benchmark ran 3 Sessions with 5 Runs of each Test in each Session. The medians differ by less than 1.5 % between Sessions. The Instance delivers about 4.48 GB/s of AES-256-GCM on 2 threads, about 34 GB/s of STREAM Triad bandwidth, about 49 MiB/s of boot volume throughput, and about 2.05 Gbit/s of network throughput. The boot volume is the Subsystem with the most limited performance.

## 2. Scope and goal

The goal is Characterization: the benchmark reports what the Instance delivers and compares the result only with the Oracle Baseline (2 OCPUs, 12 GB, 2 Gbps). It does not compare the Instance with other systems ([ADR 0001](adr/0001-characterize-only.md)). SPEC CPU 2017 and HPL are not in scope ([ADR 0003](adr/0003-no-spec-cpu-2017-in-repository.md)).

## 3. System under test

| Item | Value |
|---|---|
| Shape | `VM.Standard.A1.Flex`, 2 OCPUs, 12 GB provisioned memory |
| Processor | Neoverse-N1, 1 thread per core, KVM guest |
| Operating system | Oracle Linux Server 9.8, kernel `6.12.0-206.104.4.4.el9uek.aarch64` |
| Boot volume | 100 GB (`/` has 30 GB of file system space) |
| Region | us-sanjose-1 |

The guest shows `MemTotal` of 11,159,744 kB (about 10.6 GiB) for the 12 GB shape. The benchmark did not verify the cause.

## 4. Methodology

1. **Baseline first.** Each result refers to the Oracle shape specification.
2. **Record everything.** Each Session writes `env.json` with the kernel, CPU, memory, shape, and tool versions.
3. **Change one thing at a time.** The Instance has no setting change during a Session.
4. **Repeat and report the spread.** Each Test has 5 Runs. Run 1 is a warm-up and is not used. The tables give the median of Runs 2 to 5. The spread is (maximum - minimum) / median.
5. **Compare like with like.** All Sessions use the same tools, flags, and Instance.

Three adaptations apply to a virtual machine. The guest has no `cpufreq` interface, so the CPU frequency is not visible. Benchmark threads are pinned with `taskset`. The report shows provisioned and visible memory.

### 4.1 Harness

The Harness is a set of shell scripts in `harness/`. Systemd transient timers on the Instance start each Session, so no SSH connection must stay open. The scripts run with `/bin/bash` because SELinux blocks direct execution from the timer. A temporary Peer in the same subnet receives the network traffic and is deleted afterwards ([ADR 0002](adr/0002-temporary-same-subnet-peer.md)). A failed Test writes a line to `log.txt` and the Session continues.

### 4.2 Sessions

3 Sessions start about 1 hour apart in one evening. This schedule does not separate variation between days.

## 5. Commands

The Harness runs these commands. Technical names are exact.

| Subsystem | Command |
|---|---|
| CPU | `taskset -c <cpus> openssl speed -seconds 10 -bytes 8192 -multi <threads> -evp <alg>` for `aes-256-gcm` and `sha256`, with 1 and 2 threads |
| Memory | `gcc -O3 -mcpu=native -fopenmp -DSTREAM_ARRAY_SIZE=100000000 -DNTIMES=20`, then `OMP_NUM_THREADS=2 OMP_PROC_BIND=true taskset -c 0,1 stream` |
| Boot volume | `fio --size=8G --direct=1 --ioengine=libaio --time_based --runtime=30 --ramp_time=5`, with `--rw=read` and `--rw=write` at `--bs=1M --iodepth=16`, and `--rw=randread` and `--rw=randwrite` at `--bs=4k --iodepth=32` |
| Network | `iperf3 -c <peer> -t 30 -P 1`, the same with `-R`, and `-P 4` |

To reproduce the measurement, set up `config.env`, create the Peer, copy the Harness to the Instance, and start the Sessions:

```bash
bash ~/benchmark/harness/schedule-sessions.sh 0 1 2
```

After the `DONE` file appears, copy the results to `results/`, redact the IP addresses, delete the Peer, and run:

```bash
python3 report/summarize.py results results/summary.csv
```

The [README](../README.md) has the full steps.

## 6. Results

All values are the median of Runs 2 to 5. Raw data is in `results/`, and the computed summary is `results/summary.csv`.

| Test | Session 1 | Session 2 | Session 3 | Unit |
|---|---|---|---|---|
| AES-256-GCM, 1 thread | 2.239 | 2.248 | 2.242 | GB/s |
| AES-256-GCM, 2 threads | 4.479 | 4.484 | 4.475 | GB/s |
| SHA-256, 1 thread | 1.820 | 1.820 | 1.820 | GB/s |
| SHA-256, 2 threads | 3.644 | 3.592 | 3.642 | GB/s |
| STREAM Copy | 37.91 | 37.81 | 37.60 | GB/s |
| STREAM Scale | 39.26 | 39.36 | 39.33 | GB/s |
| STREAM Add | 34.00 | 33.91 | 33.93 | GB/s |
| STREAM Triad | 34.03 | 33.99 | 34.02 | GB/s |
| Sequential read | 48.82 | 48.82 | 48.82 | MiB/s |
| Sequential write | 48.81 | 48.82 | 48.82 | MiB/s |
| Random 4 KiB read | 5,972 | 5,971 | 5,971 | IOPS |
| Random 4 KiB write | 5,962 | 5,963 | 5,962 | IOPS |
| Network forward, 1 stream | 2.050 | 2.049 | 2.050 | Gbit/s |
| Network reverse, 1 stream | 2.053 | 2.053 | 2.053 | Gbit/s |
| Network forward, 4 streams | 2.047 | 2.041 | 2.049 | Gbit/s |

## 7. Analysis

- **Stability.** The medians differ by less than 1.5 % between Sessions. The 3 Sessions give the same picture.
- **CPU scaling.** The 2-thread result is about 2 times the 1-thread result for both algorithms. The 2 OCPUs are 2 independent cores.
- **Memory.** STREAM Triad is about 34 GB/s. This is high for a 2-core allocation.
- **Boot volume.** Throughput stays at 48.8 MiB/s and random IOPS stay near 5,970 with a spread of 1.1 % or less. Values this constant suggest a limit that the volume enforces.
- **Network.** Throughput is about 2.05 Gbit/s, which is close to the 2 Gbps Baseline. Retransmits are high (about 10,500 to 11,100 for each 1-stream Run). This is consistent with a rate limit that drops packets. The benchmark did not verify this cause.

## 8. Ramifications

This section is interpretation. The data supports it, but the benchmark did not test it directly.

1. **Storage is the first bottleneck.** A workload with heavy disk I/O, such as a database with a large working set, reaches the volume limit well before it uses the CPU or memory. Keep hot data in memory and avoid swap.
2. **CPU and memory are good for the price.** For compute work such as TLS, hashing, or a build job, the Instance has enough throughput for light to medium services. Add threads up to 2 and expect near-linear scaling.
3. **Network is at the cap.** A single stream reaches the cap. More streams give no gain. Use compression or caching to reduce transfer volume.
4. **Plan for the retransmits.** Latency-sensitive traffic can see the effect of the drops at line rate. Keep the traffic below the cap.
5. **Results are repeatable.** An owner can use these values as a Baseline to detect a change, for example after a kernel update or a host migration.

## 9. Limits

- The result applies to one Instance, one region, and one evening. It does not show variation between days or physical hosts.
- Three cases show a larger spread: 2-thread AES-256-GCM in Session 3 (4.5 %), 2-thread SHA-256 in Session 2 (3.9 %), and 1-stream forward `iperf3` in Session 2 (25 %). The benchmark did not find the cause.
- A virtual machine hides CPU frequency and hardware settings.
- The Peer shares the free quota and the subnet. The network result is a result to that Peer.
- The boot volume result uses an 8 GiB file on `/` with direct I/O. Other block sizes or queue depths can give different values.
- Oracle can change the service limits. Verify the figures before you rely on them.

## 10. Conclusion

The Instance gives stable, repeatable performance. CPU and memory are strong for a free allocation. Boot volume I/O and network throughput are the limiting Subsystems. The Harness, raw data, and tools are in this repository, so any reader can repeat the measurement and check the figures.
