#!/usr/bin/env bash
# Create the Peer: one tagged NSG and one tagged A1.Flex instance that runs an iperf3 server.
# Prints the Peer private IP on the last line. Usage: create.sh PATH_TO_config.env
set -euo pipefail
source "${1:?path to config.env}"
tag='{"benchmark-peer":"true"}'
vcn_id=$(oci network subnet get --profile "$OCI_PROFILE" --subnet-id "$SUBNET_ID" \
  --query 'data."vcn-id"' --raw-output)
nsg_id=$(oci network nsg create --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" --vcn-id "$vcn_id" \
  --display-name benchmark-peer-nsg --freeform-tags "$tag" --query 'data.id' --raw-output)
oci network nsg rules add --profile "$OCI_PROFILE" --nsg-id "$nsg_id" --security-rules "[
  {\"direction\":\"INGRESS\",\"protocol\":\"6\",\"source\":\"$PEER_SOURCE_CIDR\",\"sourceType\":\"CIDR_BLOCK\",
   \"tcpOptions\":{\"destinationPortRange\":{\"min\":5201,\"max\":5201}}}]" > /dev/null
cloud_init=$(mktemp)
cat > "$cloud_init" <<'CI'
#cloud-config
runcmd:
  - dnf -y install iperf3
  - firewall-cmd --permanent --add-port=5201/tcp || true
  - firewall-cmd --reload || true
  - systemctl enable --now iperf3
CI
inst_id=$(oci compute instance launch --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" \
  --availability-domain "$AVAILABILITY_DOMAIN" --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus":2,"memoryInGBs":12}' --image-id "$IMAGE_ID" --subnet-id "$SUBNET_ID" \
  --assign-public-ip true --nsg-ids "[\"$nsg_id\"]" --display-name benchmark-peer \
  --freeform-tags "$tag" --ssh-authorized-keys-file "$SSH_PUBLIC_KEY_PATH" \
  --user-data-file "$cloud_init" --wait-for-state RUNNING --query 'data.id' --raw-output)
rm -f "$cloud_init"
oci compute instance list-vnics --profile "$OCI_PROFILE" --instance-id "$inst_id" \
  --query 'data[0]."private-ip"' --raw-output
