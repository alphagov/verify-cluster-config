#!/bin/bash

set -eu -o pipefail

: "${CLUSTER_NAME:?}"
PIPELINE_NAME="${PIPELINE_NAME:-vpc-endpoint}"
FLY_BIN="${FLY_BIN:-fly}"

$FLY_BIN -t cd-gsp sync

$FLY_BIN -t cd-gsp set-pipeline -p "${PIPELINE_NAME}" \
	--config "ci/psn.yaml" \
  --var "account-name=${CLUSTER_NAME}" \
  --var "cluster-name=${CLUSTER_NAME}" \
  --var "concourse-pipeline-name=${PIPELINE_NAME}" \
  --var "concourse-team=gsp" \
  --yaml-var "config-approvers=[noone]" \
  --var "github-resource-image=govsvc/concourse-github-resource" \
  --var "github-resource-tag=gsp-v1.0.44" \
  --yaml-var "trusted-developer-keys=[]" \
	--check-creds "$@"

$FLY_BIN -t cd-gsp expose-pipeline -p "${PIPELINE_NAME}"
