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

TESTNET_DIR=$1
ADDRS=$2

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
	ansible_testnet=$(echo $TESTNET_DIR | sed 's_^\./ansible_._')
	ansible-playbook ./ansible/testapp-reinit.yaml --limit=ephemeral -e "testnet_dir=$ansible_testnet" -f 20

	# Wait for all of the ephemeral hosts to be running.
	addrs=( `echo $ADDRS | sed 's/,/ /g'` )
	for addr in $addrs; do
		while ! running $addr; do
			sleep 2
		done
	done

	echo "Ephemeral nodes are running"
	# Once a node has completed blocksync, shut it down.
	h=$(heighest `ansible all --list-hosts --limit validators | tail +2 | paste -s -d, - | tr -d ' '`)
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
	ansible-playbook ./ansible/testapp-stop.yaml --limit=ephemeral -e "testnet_dir=./rotating"
done
