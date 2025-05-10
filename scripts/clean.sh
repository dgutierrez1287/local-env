#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2

echo "Cleaning the files created for ${CLUSTER_NAME}"
echo "----------------------------------------------"
echo ""

## Get some cluster settings for locations #
echo "getting cluster settings"
echo ""
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')
TERRAFORM_ENV=$(echo $SETTINGS | jq -r '.terraformEnv')

echo "Cluster Settings"
echo "-----------------------------"
echo "kube context: ${KUBE_CONTEXT}"
echo "terraform env: ${TERRAFORM_ENV}"
echo "repo dir: ${REPO_DIR}"
echo ""
echo ""

## clear vault keys file ##
echo "cleaning vault tokens file"
rm -f "${REPO_DIR}/secrets/${KUBE_CONTEXT}_vault-keys.json"
echo ""
echo ""

## clear secrets tmp dir ##
echo "cleaning the secrets tmp dir"
rm -rf "${REPO_DIR}/secrets/tmp"
echo ""
echo ""

## clear bootstrap terraform file ##
echo "cleaning bootstrap terraform files"
TERRAFORM_DIR="${REPO_DIR}/../infra-terraform/${TERRAFORM_ENV}/bootstrap"
echo "terraform dir: ${TERRAFORM_DIR}"
echo ""
rm -rf "$TERRAFORM_DIR/.terraform"
rm -f "$TERRAFORM_DIR/.terraform.lock.hcl"
rm -f "$TERRAFORM_DIR/terraform.tfvars"
echo ""
echo ""

## clean infra-control terraform files
echo "cleaning infra-control terraform files"
TERRAFORM_DIR="${REPO_DIR}/../infra-terraform/${TERRAFORM_ENV}/infra-control"
echo "terraform dir: ${TERRAFORM_DIR}"
echo ""
rm -rf "$TERRAFORM_DIR/.terraform"
rm -f "$TERRAFORM_DIR/.terraform.lock.hcl"
rm -f "$TERRAFORM_DIR/terraform.tfvars"
echo ""
echo ""
