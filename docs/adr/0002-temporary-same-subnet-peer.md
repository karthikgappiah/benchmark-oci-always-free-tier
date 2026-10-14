# Measure the network with a temporary same-subnet Peer

A network test against the loopback interface does not use the network, so it is not a valid network result. We create a second `VM.Standard.A1.Flex` instance (the Peer) in the same subnet as the Instance. The Peer uses the free quota that remains. All Peer resources have the tag `benchmark-peer`. The harness deletes them after the tests and verifies that no tagged resource remains.

## Considered options

- Use the Mac as the Peer. Rejected: the home link and the Internet add noise that is outside the Instance.
- Skip the network test. Rejected: the network is a Subsystem that readers expect to see.
