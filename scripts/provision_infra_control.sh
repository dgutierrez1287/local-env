#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2
DIRECTION=$3

echo "Provisioning infra control stack for ${CLUSTER_NAME}"
echo "----------------------------------------------------"
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

if [[ "${DIRECTION}" == "up" ]]; then

# run terraform for infra control cluster
echo "running terraform"
echo "========================================="

TERRAFORM_DIR="${REPO_DIR}/../infra-terraform/${TERRAFORM_ENV}/infra-control"
echo "terraform dir: ${TERRAFORM_DIR}"
echo ""

echo "clearing a terraform.tfvars thats present"
rm -f "$TERRAFORM_DIR/terraform.tfvars"
echo ""

echo "writing out terraform.tfvars file for dynamic variables"
echo "kube_context = \"${KUBE_CONTEXT}\"" > "$TERRAFORM_DIR/terraform.tfvars"
echo ""

echo "running terraform init and apply"
pushd $TERRAFORM_DIR
  terraform init
  terraform apply -auto-approve
popd
echo ""
echo ""


# run the helm file 
echo "running infra-control helmfile"
helmfile apply -e "${HELMFILE_ENV}" -f "${REPO_DIR}/../k8s-resources/helmfiles/infra-control"

if [[ $? -ne 0 ]]; then
  echo "ERROR: running infra-control helmfile"
  exit 123
fi

echo ""
echo ""

echo "infra-control stack provisioning complete"

fi

if [[ "${DIRECTION}" == "down" ]]; then

echo "destroying the helmstack"
helmfile destroy -e "${HELMFILE_ENV}" -f "${REPO_DIR}/../k8s-resources/helmfiles/infra-control"

if [[ $? -ne 0 ]]; then
  echo "ERROR: destroying the infra-control helmfile"
  exit 123
fi

echo ""

echo "destroying the terraform stack"
echo "========================================"

TERRAFORM_DIR="${REPO_DIR}/../infra-terraform/${TERRAFORM_ENV}/infra-control"
echo "terraform dir: ${TERRAFORM_DIR}"
echo ""

pushd $TERRAFORM_DIR
  terraform init
  terraform destroy -auto-approve
popd
echo ""

echo "cleaning up terraform files"
rm -rf "$TERRAFORM_DIR/.terraform"
rm -f "$TERRAFORM_DIR/.terraform.lock.hcl"
rm -f "$TERRAFORM_DIR/terraform.tfvars"
echo ""
echo ""
fi

