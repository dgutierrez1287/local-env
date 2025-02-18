# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Detect OS
OS := $(shell uname)

help: 
	@echo "Local Kube Cluster Management"
