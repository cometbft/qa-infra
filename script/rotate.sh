#!/bin/bash
set -euo pipefail

# The functionality need from sed in this script is not covered by POSIX; it uses different syntax
# in gnu sed and in BSD sed. These helper variables have been introduced to deal with those differences.
# Moreover, sed's in place mode requires flag '-i ""' in BSD sed, which makes the use of 'eval'
# necessary every time 'sed -i' is called in order to re-interpret the flag's contents when stored
# in a variable.
INPLACE_SED_FLAG='-i'
SED_BW='\b' # No difference needed between beginning of word and end of word in Linux
SED_EW='\b'
if [[ $(uname) == "Darwin" ]]; then
	INPLACE_SED_FLAG='-i.bak'
	SED_BW='[[:<:]]' #Beginning of word in regex
	SED_EW='[[:>:]]' #End of word in regex
fi

VERSION=$1
ADDRS=$2


# Ephemeral-configs creates the set of configuration files for the ephemeral
# nodes. It generates a set of non-validating full node configuration files.
# To produce these, the function extracts details from the already constructed
# testnet configuration files, such as the genesis file and the seed node
# addresses. Once completed, there will be a set of configuration files that
# produce nodes that can be run on an existing network under ./ansible/rotating/.
ephemeral-configs() {
	ADDRS=$1
	size=`echo $ADDRS | tr , '\n' | wc -l`

	echo > ./rotating.toml

	# Add a set of dummy nodes. These nodes will not appear in the testnet
	# The config script generates the same keys, so we need to generate a set
	# of fake configurations, one for each node that exists in the testnet, so
	# that the runner script will create keys that are not part of the existing
	# network.
	c=`grep "^\[.*\]$" ./testnet.toml | wc -l`
	for i in `seq 1 $c`; do
		printf "[node.ab%03d]\n" "$i" >> ./rotating.toml
		echo "mode = \"full\"" >> ./rotating.toml
		echo >> ./rotating.toml
	done

	for i in `seq 1 $size`; do
		printf "[node.ephemeral%03d]\n" "$i" >> ./rotating.toml
		echo "mode = \"full\"" >> ./rotating.toml
		echo >> ./rotating.toml
	done

	go run github.com/cometbft/cometbft/test/e2e/runner@$VERSION setup -f ./rotating.toml
	rm ./rotating.toml

	for d in `find  ./rotating -maxdepth 1 -path './rotating/ab*'  -type d`; do
		rm -rf "$d"
	done

	# Update the persistent peers for all of the ephemeral nodes to match the persistent peers
	# of one of the validators.
	seeds=`grep -REh 'seeds = "[0-9a-z]+' ./ansible/testnet | sed -n 's/seeds = "\(.*\)"/\1/p' | sort | uniq | paste -s -d, -`
	for d in `find  ./rotating -maxdepth 1 -path './rotating/ephemeral*'  -type d | tr -d .`; do
		num=`basename $d | sed 's/ephemeral0*\([1-9][0-9]*\)/\1/'`
		valconf=`find . -regex "./ansible/testnet/validator0*$num/config/config.toml"`
		rotconf=".$d/config/config.toml"
		sed $INPLACE_SED_FLAG "s/seeds = .*/seeds = \"$seeds\"/g" $rotconf
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

	for f in `find ./rotating/ -type f -name config.toml`; do
		while read old <&3 && read new <&4; do
			sed $INPLACE_SED_FLAG "s/$SED_BW$old$SED_EW/$new/g" $f
		done 3< <(echo $old_ips | tr ' ' '\n') 4< <(echo $ADDRS | tr , '\n' )

		# Enable blocksync / fastsync. In v0.37 the name was changed to blocksync
		# so these two lines exist so that both v0.34 and v0.37 will correctly
		# be updated by this script.
		sed $INPLACE_SED_FLAG "s/fast_sync = false/fast_sync = true/g" $f
		sed $INPLACE_SED_FLAG "s/block_sync = false/block_sync = true/g" $f

		sed $INPLACE_SED_FLAG "430,440s/enable = false/enable = true/g" $f
		sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/g" $f

		# Delete all persistent peers. The e2e runner code automatically
		# sets all nodes as persistent peers if no other peers are set. We
		# override this behavior by providing a seed for each node. We
		# Want to bring up the ephemeral nodes and have them connect using
		# seed nodes instead of using persistent peers to simulate a real
		# network.
		sed $INPLACE_SED_FLAG "s/persistent_peers = .*/persistent_peers = \"\"/g" $f
	done

	rm -rf ./ansible/rotating
	mv ./rotating ./ansible/
}

# Running determines if the node address, provided as the first argument, is
# currently running by querying its RPC endpoint. It returns 0 (success) if the
# RPC curl succeeds and 1 otherwise.
running() {
	ra=$1

	if curl $ra:26657/ 2>&1 > /dev/null; then
		return 0
	fi
	return 1
}

# Heighest queries all of the node addresses in the provided list and determines
# the 'greatest' height of all the nodes.
heighest() {
	addresses=( `echo $1 | sed 's/,/ /g'`)
	current="-1"
	for a in $addresses; do 
		ha=`curl --silent $a:26657/status | jq '.result.sync_info.latest_block_height' | tr -d '"'`
		if [ $ha -ge $current ]; then
			current=$ha
		fi
	done
	echo $current
}

# Behind queries the supplied node address and checks to see how far 'behind'
# the provided height the node is. Returns 0 (success) if the node is less than
# 100 blocks behind and returns 1 otherwise.
behind() {
	address=$1
	heighest=$2
	ch=`curl --silent $address:26657/status | jq '.result.sync_info.latest_block_height' | tr -d '"'`
	echo "distance($address): $ch --> $heighest"
	if [ $ch -le `expr $heighest - 100` ]; then
		return 0
	fi
	return 1
}

while true; do
	ephemeral-configs `echo "$ADDRS"`
	ansible-playbook ./ansible/re-init-testapp.yaml -u root -i ./ansible/hosts --limit=ephemeral -e "testnet_dir=./rotating" -f 20

	# Wait for all of the ephemeral hosts to be running.
	addrs=( `echo $ADDRS | sed 's/,/ /g'` )
	for addr in $addrs; do
		while ! running $addr; do
			sleep 2
		done
	done

	echo "Ephemeral nodes are running"
	# Once a node has completed blocksync, shut it down.
	h=$(heighest `ansible all --list-hosts -i ./ansible/hosts --limit validators | tail +2 | paste -s -d, - | tr -d ' '`)
	addrs=( `echo $ADDRS | sed 's/,/ /g'` )
	while [ ${#addrs[@]} -gt 0 ]; do
		echo "New iteration: addrs=${addrs[@]}"
		addr=${addrs[0]}
		addrs=( ${addrs[@]:1} )
		if behind $addr $h; then
		    if [ ${#addrs[@]} -gt 0 ]; then
				addrs=( ${addrs[@]} $addr )
			else
				addrs=( $addr )
			fi
			sleep 1
		fi
	done
	echo "Ephemeral have all completed blocksync"
	ansible-playbook ./ansible/stop-testapp.yaml -u root -i ./ansible/hosts --limit=ephemeral
done
