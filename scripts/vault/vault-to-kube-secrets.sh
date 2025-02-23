#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
KUBE_CONTEXT=$2

VAULT_KEYS_FILE="${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json"
VAULT_UNSEAL_B64=$(cat "${VAULT_KEYS_FILE}" | jq -r '.unseal_keys_b64.[0]')
VAULT_UNSEAL_HEX=$(cat "${VAULT_KEYS_FILE}" | jq -r '.unseal_keys_hex.[0]')
VAULT_ROOT_TOKEN=$(cat "${VAULT_KEYS_FILE}" | jq -r '.root_token')

mkdir "$REPO_DIR/secrets/tmp"

echo "$VAULT_UNSEAL_B64" > "$REPO_DIR/secrets/tmp/vault_unseal_b64.txt"
echo "$VAULT_ROOT_TOKEN" > "$REPO_DIR/secrets/tmp/vault_root_token.txt"

echo "creating vault secret"
kubectl create secret generic vault-secret \
  --context ${KUBE_CONTEXT} \
  --from-literal=unseal_hex="$VAULT_UNSEAL_HEX" \
  --from-file=unseal_b64="$REPO_DIR/secrets/tmp/vault_unseal_b64.txt" \
  --from-file=root_token="$REPO_DIR/secrets/tmp/vault_root_token.txt" \
  --namespace=vault \

