#!/bin/bash

set -eu -o pipefail

: "${CLUSTER_NAME:?}"
: "${ACCOUNT_ROLE_ARN:?}"
: "${USER_CONFIGS:?}"
PIPELINE_NAME="${PIPELINE_NAME:-${CLUSTER_NAME}-vpc-endpoint}"
FLY_BIN="${FLY_BIN:-fly}"

$FLY_BIN -t cd-gsp sync

approvers="/tmp/gsp-release-approvers.yaml"
echo -n "config-approvers: " > "${approvers}"
yq . ${USER_CONFIGS}/*.yaml \
	| jq -c -s "[.[].github] | unique | sort" \
	>> "${approvers}"

trusted="/tmp/gsp-release-keys.yaml"
echo -n "trusted-developer-keys: " > "${trusted}"
yq . ${USER_CONFIGS}/*.yaml \
	| jq -c -s '[ .[].pub ] | sort' \
	>> "${trusted}"


$FLY_BIN -t cd-gsp set-pipeline -p "${PIPELINE_NAME}" \
	--config "ci/psn.yaml" \
	--load-vars-from "${approvers}" \
	--load-vars-from "${trusted}" \
  --var "account-name=${CLUSTER_NAME}" \
  --var "cluster-name=${CLUSTER_NAME}" \
  --var "concourse-pipeline-name=${PIPELINE_NAME}" \
  --var "concourse-team=gsp" \
  --var "account-role-arn=${ACCOUNT_ROLE_ARN}" \
  --var "github-resource-image=govsvc/concourse-github-resource" \
  --var "github-resource-tag=gsp-va191b03" \
	--check-creds "$@"

$FLY_BIN -t cd-gsp expose-pipeline -p "${PIPELINE_NAME}"
