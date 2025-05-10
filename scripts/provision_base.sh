#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2

echo "Provisioning the base for ${CLUSTER_NAME}"
echo "----------------------------------------"
echo ""

##  Get cluster settings ##
echo "getting cluster settings"
echo ""
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

LOCALKUBE_NAME=$(echo $SETTINGS | jq -r '.localKubeName')
KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
HELMFILE_ENV=$(echo $SETTINGS | jq -r '.helmfileEnvironment')
CLUSTER_VIP=$(echo $SETTINGS | jq -r '.vip')
DOMAIN_SUFFIX=$(echo $SETTINGS | jq -r '.domainSuffix')
MINIO_ALIAS=$(echo $SETTINGS | jq -r '.minioAlias')
TERRAFORM_ENV=$(echo $SETTINGS | jq -r '.terraformEnv') 

echo "Cluster Settings"
echo "----------------------------"
echo "local-kube name: ${LOCALKUBE_NAME}"
echo "kube context: ${KUBE_CONTEXT}"
echo "helmfile environment: ${HELMFILE_ENV}"
echo "cluster vip: ${CLUSTER_VIP}"
echo "domain suffix: ${DOMAIN_SUFFIX}"
echo "minio alias: ${MINIO_ALIAS}"
echo "terraform env: ${TERRAFORM_ENV}"
echo "repo dir: ${REPO_DIR}"
echo ""
echo ""

## check if cluster is up before provisioning
echo "checking if cluster is up and running"
status_output=$(local-kube cluster-status --cluster $LOCALKUBE_NAME -m)
exit_code=$(echo $status_output | jq -r '.exitCode')

if [[ $exit_code -ne 0 ]]; then
  echo "Error getting cluster status"
  exit 100
fi 

cluster_status=$(echo $status_output | jq -r '.clusterStatus')

if [[ "${cluster_status}" != "running" ]]; then
  echo  "Error cluster is not running, please check"
  exit 100
fi

## adding secrets for the environment wildcard cert and homelabCA cert ##
echo "writing out certs to kubernetes"
bash ${REPO_DIR}/scripts/kubernetes/cert_secret.sh ${REPO_DIR} ${CLUSTER_NAME}

echo ""

## Provision cluster base with helmfile ##
echo "running cluster base helmfile"
helmfile apply -e "${HELMFILE_ENV}" -f "${REPO_DIR}/../k8s-resources/helmfiles/cluster-base"

if [[ $? -ne 0 ]]; then
  echo "ERROR: running cluster base helmfile"
  exit 123
fi
echo ""

## Provision Vault with helmfile ##
echo "running vault helmfile"
helmfile apply -e ${HELMFILE_ENV} -f ${REPO_DIR}/../k8s-resources/helmfiles/vault.yaml

if [[ $? -ne 0 ]]; then
  echo "ERROR: running vault helmfile"
  exit 123
fi
echo ""

## Provision Minio with helmfile ##
echo "running minio helmfile"
helmfile apply -e ${HELMFILE_ENV} -f ${REPO_DIR}/../k8s-resources/helmfiles/minio.yaml

if [[ $? -ne 0 ]]; then
  echo "ERROR: running minio helmfile"
  exit 123
fi
echo ""

## Provision local cluster base items ##
echo "running local-cluster-base"
helmfile apply -e ${HELMFILE_ENV} -f "${REPO_DIR}/../k8s-resources/helmfiles/local-cluster-base"

if [[ $? -ne 0 ]]; then
  echo "ERROR: running local cluster base helmfile"
  exit 123
fi
echo ""

echo "sleeping for 1 minutes to let everything deploy"
echo ""
sleep 60

## create terraform state bucket ##
echo "creating terraform state bucket on minio"
echo "NOTE: errors are ignored incase the script is being re-run"
mc mb ${MINIO_ALIAS}/terraform-state

echo ""

## init and unseal vault ##
echo "initialize and unseal vault to make it ready for use"
bash ${REPO_DIR}/scripts/vault/init_unseal.sh ${REPO_DIR} ${KUBE_CONTEXT}

echo ""

## write vault unseal key and root token to kubernetes
echo "write out vault unseal key and root token to kube"
bash ${REPO_DIR}/scripts/vault/vault-to-kube-secrets.sh ${REPO_DIR} ${KUBE_CONTEXT}

echo ""

## bootstrap vault and the cluster ##
echo "bootstrapping vault and the cluster with terraform"
bash ${REPO_DIR}/scripts/terraform/run-bootstrap.sh ${REPO_DIR} ${CLUSTER_NAME}

echo ""

## restart coredns pod to ensure dns changes take affect ##
echo "restarting core-dns pods"
kubectl --context ${KUBE_CONTEXT} rollout restart deployment coredns -n kube-system

echo ""

echo "Base Provision of the local cluster is complete"
echo "-----------------------------------------------"
