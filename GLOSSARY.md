# OCI Always Free Tier Benchmark

A reproducible benchmark that characterizes the performance of one Oracle Cloud Infrastructure (OCI) Always Free Ampere A1 compute instance.

## Language

**Instance**:
The single OCI Ampere A1 compute instance under test (2 OCPUs, 12 GB memory, 100 GB boot volume, Oracle Linux 9).
_Avoid_: Server, VPS, VM, host

**Characterization**:
The act of measuring and reporting what performance the Instance delivers, with no comparison to other systems.
_Avoid_: Comparison, validation

**Subsystem**:
One part of the Instance that a benchmark measures: CPU, memory, or boot volume storage.
_Avoid_: Component, area, category

**Harness**:
The set of scripts in this repository that install tools on the Instance, run benchmarks, and collect raw results.
_Avoid_: Framework, suite

**Peer**:
A temporary second OCI instance in the same subnet that exchanges network traffic with the Instance. It exists only for the network tests and is deleted afterwards.
_Avoid_: Client, remote, endpoint

## Measurement

**Test**:
One tool configuration that measures one Subsystem property, for example STREAM Triad bandwidth or fio 4 KiB random read.
_Avoid_: Benchmark (ambiguous: use for the whole project), workload, job

**Run**:
One execution of one Test, producing one raw result.
_Avoid_: Trial, iteration, attempt

**Session**:
A time window in which every Test is run 5 times. A full measurement uses 3 Sessions.
_Avoid_: Batch, round, campaign

**Baseline**:
The Oracle-published specification of the Instance shape (2 OCPUs, 12 GB, 2 Gbps), used as the reference for reported results.
_Avoid_: Reference, expected value

**Estimate**:
A result produced with a licensed suite (such as SPEC CPU 2017) outside its reportable rules, labelled as such.
_Avoid_: Score, official result
