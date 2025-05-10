# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Detect OS
OS := $(shell uname)

help: 
	@echo "Local Kube Cluster Management"
	@echo "============================="
	@echo "help - lists all the help targets"
	@echo ""
	@echo "Single Node Control"
	@echo "============================="
	@echo "sn-bootstrap - Bootstraps the cluster (initializes vault and sets up vault and configs the cluster integration)"
	@echo "sn-clean - Cleans all the files for vault and terraform" 
	@echo "sn-load-vault - Loads secrets into vault needed by applications deployments"
	@echo "sn-infra-control - deploys or updates the infra-control stack for testing"
	@echo "sn-infra-db-forward - forwards the db port for the infra-control database"

## Single Node Cluster ##
sn-bootstrap:
	/usr/bin/env bash scripts/provision_base.sh ${MAKEFILE_DIR} "local-single-node"

sn-clean:
	/usr/bin/env bash scripts/clean.sh ${MAKEFILE_DIR} "local-single-node"

sn-load-vault:
	/usr/bin/env bash scripts/vault/load_vault.sh ${MAKEFILE_DIR} "local-single-node"

sn-infra-control:
	/usr/bin/env bash scripts/provision_infra_control.sh ${MAKEFILE_DIR} "local-single-node"

sn-infra-db-forward:
	/usr/bin/env bash scripts/kubernetes/db_port_forward.sh ${MAKEFILE_DIR} "local-single-node" "infra" "infra-control-cluster"
