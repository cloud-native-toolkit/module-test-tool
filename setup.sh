#!/usr/bin/env bash

sudo chown devops /tmp/workspace
mkdir -p /tmp/workspace/module
cp -R /terraform/module/test/stages/* /tmp/workspace
cp -R /terraform/module/* /tmp/workspace/module
cp /terraform/terraform.tfvars /tmp/workspace

echo "Environment setup."
