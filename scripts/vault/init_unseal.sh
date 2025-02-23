#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
KUBE_CONTEXT=$2

VAULT_KEYS_FILE="${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json"

## get vault status ##
VAULT_STATUS=$(kubectl --context="${KUBE_CONTEXT}" exec -n vault vault-0 -- vault status --format json)
VAULT_SEALED=$(echo $VAULT_STATUS | jq -r '.sealed')

if [ ! -f "${VAULT_KEYS_FILE}" ]; then 
  ## run vault init to initalize vault ##
  echo "initializing vault"
  kubectl --context ${KUBE_CONTEXT} exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > "${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json"
else
  echo "vault is already initialized"
fi

echo ""

echo "vault seal status: ${VAULT_SEALED}"
if [[ "${VAULT_SEALED}" == "true" ]]; then
  echo "getting vault unseal key"
  VAULT_SETTINGS=$(cat ${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json)
  UNSEAL_KEY=$(echo $VAULT_SETTINGS | jq -r '.unseal_keys_b64.[0]')

  echo "unseal vault"
  kubectl --context ${KUBE_CONTEXT} exec -n vault vault-0 -- vault operator unseal ${UNSEAL_KEY}
else 
  echo "vault is already unsealed"
fi 

