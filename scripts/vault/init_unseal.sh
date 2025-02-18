#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

KUBE_CONTEXT=$1

## run vault init to initalize vault ##
echo "initializing vault"
echo "NOTE: errors are ignored incase the script is being re-run"
kubectl --context ${KUBE_CONTEXT} exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > ${SCRIPT_DIR}/../../secrets/${KUBE_CONTEXT}_vault-keys.json

echo ""

echo "getting vault unseal key"
VAULT_SETTINGS=$(cat ${SCRIPT_DIR}/../../secrets/${KUBE_CONTEXT}_vault-keys.json)
UNSEAL_KEY=$(echo $VAULT_SETTINGS | jq -r '.unseal_keys_b64.[0]')

echo "unseal vault"
kubectl --context ${KUBE_CONTEXT} exec -n vault vault-0 -- vault operator unseal ${UNSEAL_KEY}

