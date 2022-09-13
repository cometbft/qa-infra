#!/bin/bash
set -euo pipefail

INPLACE_SED_FLAG='-i ""'
if sed --version | head -1 | grep GNU; then
	INPLACE_SED_FLAG='-i'
fi

VERSION=$1
ADDRS=$1

ephemeral-configs() {
	ADDRS=$1
	size=`echo $ADDRS | tr , '\n' | wc -l`

	echo > ./rotating.toml
	for i in `seq 0 $(expr $size - 1)`; do
		printf "[node.ephemeral%02d]" "$i" >> ./rotating.toml
		echo >> ./rotating.toml
	done

	go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./rotating.toml
	rm ./rotating.toml


	persistent_peers=`grep 'persistent-peers = ".*' ./ansible/testnet/validator00/config/config.toml | tr -d '\n'`
	find ./rotating/ -name config.toml -type f | xargs -I{} sed -i "s/persistent-peers = .*/$persistent_peers/g"  {}

	genesis=`find ./ansible/testnet  -name genesis.json -type f | head -n 1`
	find ./rotating/ -name genesis.json -type f | xargs -I{} cp $genesis {}

	old_ips=`grep -E '(ipv4_address|container_name)' ./rotating/docker-compose.yml \
		| sed 's/^.*ipv4_address: \(.*\)/\1/g' \
		| sed 's/.*container_name: \(.*\)/\1/g' \
		| paste -sd ' \n' - \
		| sort -k1 \
		| cut -d ' ' -f2`

	while read old <&3 && read new <&4; do
		find ./rotating/ -type f | xargs -I{} sed -i "s/$old/$new/g" {}
	done 3< <(echo $old_ips | tr ' ' '\n') 4< <(echo $ADDRS | tr , '\n' )

	# Enable blocksync
	find ./rotating/ -type f -name config.toml \
		| xargs -I{} sed -i "430,440s/enable = false/enable = true/g" {}

	rm -rf ./ansible/rotating
	mv ./rotating ./ansible/
}

running() {
	addr=$1

	if curl $addr:26657/ 2>&1 > /dev/null; then
		# in bash, 0 is true and 1 is false
		return 0
	fi
	return 1
}

blocksyncing() {
	addr=$1

	if [ `curl $addr:26657/status | jq '.result.sync_info.catching_up'` = true ]; then
		# in bash, 0 is true and 1 is false
		return 0
	fi
	return 1
}

while true; do
	ephemeral-configs `echo $ADDRS`
	ansible-playbook ./ansible/re-init-testapp.yaml -u root -i ./ansible/hosts --limit=ephemeral -e "testnet_dir=./rotating"

	oldIFS=$IFS
	IFS=","; for addr in $ADDRS; do
	IFS=$oldIFS
		while ! running $addr; do
			sleep 2
		done
		while blocksyncing $addr; do
			sleep 2
		done
	done
	IFS=$oldIFS
done
