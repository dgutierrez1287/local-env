#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CLUSTER_NAME=$1

echo "Provisioning the base for ${CLUSTER_NAME}"
echo "----------------------------------------"
echo ""

##  Get cluster settings ##
echo "getting cluster settings"
echo ""
SETTINGS=$(cat ${SCRIPT_DIR}/../settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
HELMFILE_ENV=$(echo $SETTINGS | jq -r '.helmfileEnvironment')
CLUSTER_VIP=$(echo $SETTINGS | jq -r '.vip')
DOMAIN_SUFFIX=$(echo $SETTINGS | jq -r '.domainSuffix')
MINIO_ALIAS=$(echo $SETTINGS | jq -r '.minioAlias')
TERRAFORM_ENV=$(echo $SETTINGS | jq -r '.terraformEnv') 

echo "Cluster Settings"
echo "----------------------------"
echo "kube context: ${KUBE_CONTEXT}"
echo "helmfile environment: ${HELMFILE_ENV}"
echo "cluster vip: ${CLUSTER_VIP}"
echo "domain suffix: ${DOMAIN_SUFFIX}"
echo "minio alias: ${MINIO_ALIAS}"
echo "terraform env: ${TERRAFORM_ENV}"
echo ""
echo ""

## Provision cluster base with helmfile ##
echo "running cluster base helmfile"
helmfile apply -e ${HELMFILE_ENV} -f ${SCRIPT_DIR}/../../k8s-resources/helmfiles/cluster-base

if [[ $? -ne 0 ]]; then
  echo "ERROR: running cluster base helmfile"
  exit 123
fi
echo ""

## Provision Vault with helmfile ##
echo "running vault helmfile"
helmfile apply -e ${HELMFILE_ENV} -f ${SCRIPT_DIR}/../../k8s-resources/helmfiles/vault.yaml

if [[ $? -ne 0 ]]; then
  echo "ERROR: running vault helmfile"
  exit 123
fi
echo ""

## Provision Minio with helmfile ##
echo "running minio helmfile"
helmfile apply -e ${HELMFILE_ENV} -f ${SCRIPT_DIR}/../../k8s-resources/helmfiles/minio.yaml

if [[ $? -ne 0 ]]; then
  echo "ERROR: running minio helmfile"
  exit 123
fi
echo ""

## create terraform state bucket ##
echo "creating terraform state bucket on minio"
echo "NOTE: errors are ignored incase the script is being re-run"
mc mb ${MINIO_ALIAS}/terraform-state

echo ""

## init and unseal vault ##
echo "initialize and unseal vault to make it ready for use"
bash vault/init_unseal.sh ${KUBE_CONTEXT}

echo ""

