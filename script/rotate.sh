#!/bin/bash
set -euo pipefail

addrlist=$1
nodelist=$2

start-ephemeral() {
	addr=$1
	node=$2

	ansible-playbook ./ansible/remove-testapp-data.yaml -u root -i ./ansible/hosts --limit $addr
	old=`grep -E '(ipv4_address|container_name)' ./ansible/full-testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' | sed -n "s/$node \(.*\)/\1/p"`
	find ./ansible/full-testnet -type f | xargs -I{} sed -i "s/$old/$addr/g" {}
	ansible-playbook ./ansible/init-testapp.yaml -u root -i ./ansible/hosts --limit $addr -e "local_config_dir=./full-testnet/$node"
	ansible-playbook ./ansible/start-testapp.yaml -u root -i ./ansible/hosts --limit $addr -e "local_config_dir=./full-testnet/$node"
}

blocksyncing() {
	addr=$1

	if [ `curl $addr:26657/status | jq '.result.sync_info.catching_up'` = true ]; then
		return 1
	fi
	return 0
}

IFS=","; for addr in $addrlist; do
	IFS=" "
	node=`echo $nodelist | cut -d, -f1`
	start-ephemeral `echo $addr` `echo $node`
	nodelist=`echo $nodelist | cut -d, -f 2-`
done

IFS=","; for node in $nodelist; do
	IFS=" "
	addr=`echo $addrlist | cut -d, -f1`

	while [ `blocksyncing $addr` = true ]; do
		sleep 10
	done

	start-ephemeral `echo $addr` `echo $node`
	# cons the cdr onto the car of the list
	addrlist=`echo $addrlist | cut -d, -f 2-`,`echo $addrlist | cut -d, -f1`
done
