#!/bin/bash
set -euo pipefail

INPLACE_SED_FLAG='-i'
if [[ $(uname) == "Darwin" ]]; then
	INPLACE_SED_FLAG='-i ""'
fi

VERSION=$1
ADDRS=$2

ephemeral-configs() {
	ADDRS=$1
	size=`echo $ADDRS | tr , '\n' | wc -l`

	echo > ./rotating.toml
	for i in `seq 1 $(expr $size)`; do
		printf "[node.ephemeral%02d]" "$i" >> ./rotating.toml
		echo >> ./rotating.toml
	done

	go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./rotating.toml
	rm ./rotating.toml

	# Update the persistent peers for all of the ephemeral nodes to match the persistent peers
	# of one of the validators.
	for d in `find  ./rotating -maxdepth 1 -path './rotating/ephemeral*'  -type d | tr -d .`; do
		num=`basename $d | sed 's/ephemeral\(.*\)/\1/'`
		valconf=`find . -regex "./ansible/testnet/validator0*$num/config/config.toml"`
		rotconf=".$d/config/config.toml"
		persistent_peers=`grep 'persistent_peers = ".*' $valconf | tr -d '\n'`
		sed $INPLACE_SED_FLAG "s/persistent_peers = .*/$persistent_peers/g" $rotconf
		echo `grep 'persistent_peers = ".*' $rotconf`
	done

	# Copy over the genesis file from the current testnet to the ephemeral node directories.
	genesis=`find . -regex "./ansible/testnet/validator0*1/config/genesis.json" | head -1`
	find ./rotating/ -name genesis.json -type f | xargs -I{} cp $genesis {}

	# Gather the set of old ips as listed in the docker compose file.
	old_ips=`grep -E '(ipv4_address|container_name)' ./rotating/docker-compose.yml \
		| sed 's/^.*ipv4_address: \(.*\)/\1/g' \
		| sed 's/.*container_name: \(.*\)/\1/g' \
		| paste -sd ' \n' - \
		| sort -k1 \
		| cut -d ' ' -f2`

	for f in `find ./rotating/ -name config.toml`; do
		while read old <&3 && read new <&4; do
			sed $INPLACE_SED_FLAG "s/$old/$new/g" $f
		done 3< <(echo $old_ips | tr ' ' '\n') 4< <(echo $ADDRS | tr , '\n' )
		# Enable blocksync
		sed $INPLACE_SED_FLAG "430,440s/enable = false/enable = true/g" $f
		# Enable prometheus
		sed $INPLACE_SED_FLAG "430,440s/prometheus = .*/prometheus = true/g" $f
	done

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

	# Wait for all of the ephemeral hosts to complete blocksync.
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
