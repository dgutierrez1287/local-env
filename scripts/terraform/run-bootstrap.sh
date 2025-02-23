#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2

echo ""
echo "getting settings"
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
CLUSTER_VIP=$(echo $SETTINGS | jq -r '.vip')
TERRAFORM_ENV=$(echo $SETTINGS | jq -r '.terraformEnv')

echo "Settings"
echo "--------------------------"
echo "kube context: ${KUBE_CONTEXT}"
echo "cluster vip: ${CLUSTER_VIP}"
echo "terraform env: ${TERRAFORM_ENV}"
echo ""
echo ""

echo "getting secrets"
KUBE_CONFIG_CLUSTER=$(yq e ".contexts[] | select (.name == \"${KUBE_CONTEXT}\") | .context.cluster" ~/.kube/config)
KUBE_CA_CERT=$(yq e ".clusters[] | select(.name == \"${KUBE_CONFIG_CLUSTER}\") | .cluster.\"certificate-authority-data\"" ~/.kube/config | base64 -d | awk '{printf "%s\\n", $0}')
HL_SECRETS=$(cat ${REPO_DIR}/secrets/homelab-secrets.json)

INT_DNS_ZONE1=$(echo $HL_SECRETS | jq -r '.homelabDns.dnsZoneOne')
INT_DNS_ZONE2=$(echo $HL_SECRETS | jq -r '.homelabDns.dnsZoneTwo')
INT_DNS_SERVER1=$(echo $HL_SECRETS | jq -r '.homelabDns.dnsServer1')
INT_DNS_SERVER2=$(echo $HL_SECRETS | jq -r '.homelabDns.dnsServer2')

VAULT_TOKEN=$(cat ${REPO_DIR}/secrets/local-single-node_vault-keys.json | jq -r '.root_token')

echo "Secrets"
echo "-------------------------"
echo "kube ca cert: ${KUBE_CA_CERT}"
echo "internal DNS zone 1: ${INT_DNS_ZONE1}"
echo "internal DNS zone 2: ${INT_DNS_ZONE2}"
echo "DNS server 1: ${INT_DNS_SERVER1}"
echo "DNS server 2: ${INT_DNS_SERVER2}"
echo "Vault Token: ${VAULT_TOKEN}"
echo ""
echo ""

TERRAFORM_DIR="${REPO_DIR}/../infra-terraform/${TERRAFORM_ENV}/bootstrap"
echo "terraform dir: ${TERRAFORM_DIR}"
echo ""
echo ""

#================================================================== 

echo "clearing an terraform.tfvars thats present"
rm -f "$TERRAFORM_DIR/terraform.tfvars"
echo ""

echo "writing out terraform.tfvars file for dynamic variables"
echo "kube_context = \"${KUBE_CONTEXT}\""     > "$TERRAFORM_DIR/terraform.tfvars"
echo ""                                       >> "$TERRAFORM_DIR/terraform.tfvars"
echo "vault_token = \"${VAULT_TOKEN}\""       >> "$TERRAFORM_DIR/terraform.tfvars"
echo ""                                       >> "$TERRAFORM_DIR/terraform.tfvars"
echo "cluster_ca_cert = \"${KUBE_CA_CERT}\""  >> "$TERRAFORM_DIR/terraform.tfvars"
echo ""                                       >> "$TERRAFORM_DIR/terraform.tfvars"
echo "cluster_vip = \"${CLUSTER_VIP}\""       >> "$TERRAFORM_DIR/terraform.tfvars"
echo ""                                       >> "$TERRAFORM_DIR/terraform.tfvars"
echo "local_dns_config = {"                   >> "$TERRAFORM_DIR/terraform.tfvars"
echo "zone1 = {"                             >> "$TERRAFORM_DIR/terraform.tfvars"
echo "name" = \"$INT_DNS_ZONE1\"              >> "$TERRAFORM_DIR/terraform.tfvars"
echo "dns_server1 = \"$INT_DNS_SERVER1\""     >> "$TERRAFORM_DIR/terraform.tfvars"
echo "dns_server2 = \"$INT_DNS_SERVER2\""     >> "$TERRAFORM_DIR/terraform.tfvars"
echo "}"                                      >> "$TERRAFORM_DIR/terraform.tfvars"
echo "zone2 = {"                             >> "$TERRAFORM_DIR/terraform.tfvars"
echo "name" = \"$INT_DNS_ZONE2\"              >> "$TERRAFORM_DIR/terraform.tfvars"
echo "dns_server1 = \"$INT_DNS_SERVER1\""     >> "$TERRAFORM_DIR/terraform.tfvars"
echo "dns_server2 = \"$INT_DNS_SERVER2\""     >> "$TERRAFORM_DIR/terraform.tfvars" 
echo "}"                                      >> "$TERRAFORM_DIR/terraform.tfvars"
echo "}"                                      >> "$TERRAFORM_DIR/terraform.tfvars"

echo ""

echo "running terraform init and apply"
pushd $TERRAFORM_DIR
  terraform init
  terraform apply -auto-approve
popd

exit 0
