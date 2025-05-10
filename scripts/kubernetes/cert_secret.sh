#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2

echo ""
echo "getting settings"
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
CERT_NAME=$(echo $SETTINGS | jq -r '.certName')
TOP_CERT_DIR="${REPO_DIR}/secrets/certs"
FULL_CERT_DIR="${REPO_DIR}/secrets/certs/${CERT_NAME}"

echo "Settings"
echo "--------------------------"
echo "kube context: ${KUBE_CONTEXT}"
echo "cert name: ${CERT_NAME}"
echo "cert dir: ${FULL_CERT_DIR}"
echo "top cert dir: ${TOP_CERT_DIR}"
echo ""
echo ""

echo "creating kube secret for ${CLUSTER_NAME} certs"
kubectl create secret tls wildcard-cert \
  --context ${KUBE_CONTEXT} \
  --cert="${FULL_CERT_DIR}/${CERT_NAME}.crt" \
  --key="${FULL_CERT_DIR}/${CERT_NAME}.key" \
  --namespace=kube-system

echo "creating kube secret for local root CA cert"
kubectl create secret generic local-ca-cert \
  --context ${KUBE_CONTEXT} \
  --from-file=ca_cert="${TOP_CERT_DIR}/local-rootCA.crt" \
  --namespace=kube-system

echo "creating kube secret for homelabCA cert"
kubectl create secret generic homelab-ca-cert \
  --context ${KUBE_CONTEXT} \
  --from-file=ca_cert="${TOP_CERT_DIR}/homelabCA.crt" \
  --namespace=kube-system



