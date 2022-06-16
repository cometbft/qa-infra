#!/bin/bash
set -euo pipefail

ANSIBLE_HOSTS=$1
LOAD_RUNNER_CMD=${LOAD_RUNNER_CMD:-"go run github.com/tendermint/tendermint/test/e2e/runner@51685158fe36869ab600527b852437ca0939d0cc"}
IP_LIST=`cat ${ANSIBLE_HOSTS} | grep -v 'monitor' | grep 'ansible_host' | awk -F' ansible_host=' '{print $2}' | head -c -1 | tr '\n' ','`

${LOAD_RUNNER_CMD} load --ip-list ${IP_LIST} --seed-delta 42
