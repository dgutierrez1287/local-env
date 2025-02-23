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

## Single Node Cluster ##
sn-bootstrap:
	/usr/bin/env bash scripts/provision_base.sh ${MAKEFILE_DIR} "local-single-node"

sn-clean:
	/usr/bin/env bash scripts/clean.sh ${MAKEFILE_DIR} "local-single-node"

