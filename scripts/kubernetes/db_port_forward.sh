#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

REPO_DIR=$1
CLUSTER_NAME=$2
NAMESPACE=$3
DBCLUSTERNAME=$4

echo "Setting up port forward for kube db ${DBCLUSTERNAME}"
echo "----------------------------------------------------"
echo ""
SETTINGS=$(cat ${REPO_DIR}/settings.json | jq --arg cluster "$CLUSTER_NAME" '.[$cluster]')

LOCALKUBE_NAME=$(echo $SETTINGS | jq -r '.localKubeName')
KUBE_CONTEXT=$(echo $SETTINGS | jq -r '.kubeContext')

echo "Cluster Settings"
echo "-------------------------"
echo "local-kube name: ${LOCALKUBE_NAME}"
echo "kube context: ${KUBE_CONTEXT}"
echo "namespace: ${NAMESPACE}"
echo "db cluster name: ${DBCLUSTERNAME}"

echo "getting db pod name"
pod_name=$(kubectl get pods -n ${NAMESPACE} --context ${KUBE_CONTEXT} \
  -l cnpg.io/cluster=${DBCLUSTERNAME} -o json | jq -r '.items[].metadata.name')

echo "starting port forwarding"
kubectl port-forward -n ${NAMESPACE} --context ${KUBE_CONTEXT} pod/${pod_name} 5432:5432
