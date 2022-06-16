#!/bin/bash
set -euo pipefail

ANSIBLE_HOSTS=$1
E2E_RUNNER_VERSION=${E2E_RUNNER_VERSION:-v0.35.5}
E2E_RUNNER_URL="github.com/tendermint/tendermint/test/e2e/runner@${E2E_RUNNER_VERSION}"

# Extract the IP addresses of all of the nodes (excluding the monitoring
# server) from the Ansible hosts file. IP addresses will be in the same order
# as those generated in the docker-compose.yml file, and will be separated by
# newlines.
NEW_IPS=`cat ${ANSIBLE_HOSTS} | grep -v 'monitor' | grep 'ansible_host' | awk -F' ansible_host=' '{print $2}' | head -c -1 | tr '\n' ','`

go run ${E2E_RUNNER_URL} setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

while read old <&3 && read new <&4; do
  echo "Swapping ${old} for ${new}"
	find ./testnet/ -type f | xargs -I{} sed -i "s/$old/$new/g" {}
done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' )

# Update configuration parameters
find ./testnet/ -name 'config.toml' | xargs -I{} sed -i "s/^log-format = .*$/log-format = \"json\"/g" {}

rm -rf ./ansible/testnet
mv ./testnet ./ansible
