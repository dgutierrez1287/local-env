#!/usr/bin/env bash 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2

echo "getting cluster settings"
echo ""
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "${CLUSTER_NAME}" '.[$cluster]')

KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
DOMAIN_SUFFIX=$(echo $SETTINGS | jq -r '.domainSuffix')
CACERT_FILE_LOCAL_PATH=$(echo $SETTINGS | jq -r '.caCertFile')
CACERT_KEY_FILE_LOCAL_PATH=$(echo $SETTINGS | jq -r '.caCertKeyFile')

VAULT_KEYS_FILE="${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json"
ROOT_TOKEN="$(cat ${VAULT_KEYS_FILE} | jq -r '.root_token')"
CACERT_FILE_FULL_PATH="${REPO_DIR}/${CACERT_FILE_LOCAL_PATH}"
CACERT_KEY_FILE_FULL_PATH="${REPO_DIR}/${CACERT_KEY_FILE_LOCAL_PATH}"

echo "loading local env secrets to vault"

vault-util bulk-load \
  --skip-tls-verify \
  --token "${ROOT_TOKEN}" \
  --secrets-file "${REPO_DIR}/secrets/local-only-secrets.json" \
  --vault-url "https://vault.${DOMAIN_SUFFIX}" 
