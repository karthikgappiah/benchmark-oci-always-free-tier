#!/usr/bin/env bash
# Delete every resource tagged benchmark-peer, then list what remains. Usage: delete.sh PATH_TO_config.env
set -euo pipefail
source "${1:?path to config.env}"
q='data[?"freeform-tags"."benchmark-peer"==`true`'
for id in $(oci compute instance list --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" --all \
    --query "${q} && \"lifecycle-state\"!='TERMINATED'].id" --raw-output | tr -d '[]," '); do
  oci compute instance terminate --profile "$OCI_PROFILE" --instance-id "$id" \
    --preserve-boot-volume false --force --wait-for-state TERMINATED
done
for id in $(oci network nsg list --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" --all \
    --query "${q}].id" --raw-output | tr -d '[]," '); do
  oci network nsg delete --profile "$OCI_PROFILE" --nsg-id "$id" --force
done
echo "Remaining tagged instances:"
oci compute instance list --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" --all \
  --query "${q} && \"lifecycle-state\"!='TERMINATED'].id"
echo "Remaining tagged NSGs:"
oci network nsg list --profile "$OCI_PROFILE" -c "$COMPARTMENT_ID" --all --query "${q}].id"
