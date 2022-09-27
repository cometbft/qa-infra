#!/bin/bash
set -euo pipefail

# The functionality need from sed in this script is not covered by POSIX; it uses different syntax
# in gnu sed and in BSD sed.
# These helper variables have been introduced to deal with those differences.
# Moreover, sed's in place mode requires flag '-i ""' in BSD sed, which makes the use of 'eval'
# necessary every time 'sed -i' is called in order to re-interpret the flag's contents when stored
# in a variable.
INPLACE_SED_FLAG='-i'
SED_BW='\b' # No difference needed between beginning of word and end of word in Linux
SED_EW='\b'
if [[ $(uname) == "Darwin" ]]; then
	INPLACE_SED_FLAG='-i ""'
	SED_BW='[[:<:]]' #Beginning of word in regex
	SED_EW='[[:>:]]' #End of word in regex
fi

VERSION=$1
ADDRS=$2

ephemeral-configs() {
	ADDRS=$1
	size=`echo $ADDRS | tr , '\n' | wc -l`

	echo > ./rotating.toml
	for i in `seq 0 $(expr $size - 1)`; do
		printf "[node.ephemeral%03d]\n" "$i" >> ./rotating.toml
		echo "mode = \"full\"" >> ./rotating.toml
		echo >> ./rotating.toml
	done

	go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./rotating.toml
	rm ./rotating.toml

	# Update the persistent peers for all of the ephemeral nodes to match the persistent peers
	# of one of the validators.
	seeds=`grep -REh 'seeds = "[0-9a-z]+' ./ansible/testnet | sort | uniq`
	nseeds=`echo "$seeds" | wc -l`
	for d in `find  ./rotating -maxdepth 1 -path './rotating/ephemeral*'  -type d | tr -d .`; do
		offset=`expr $RANDOM % $nseeds + 1`
		seed=`echo "$seeds" | sed -n ${offset}p`
		rotconf=".$d/config/config.toml"
		sed $INPLACE_SED_FLAG "s/seeds = .*/$seed/g" $rotconf
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
			eval sed $INPLACE_SED_FLAG \"s/$SED_BW$old$SED_EW/$new/g\" $f
		done 3< <(echo $old_ips | tr ' ' '\n') 4< <(echo $ADDRS | tr , '\n' )
		# Enable blocksync
		# Enable blocksync
		sed $INPLACE_SED_FLAG "20,30s/fast_sync = false/fast_sync = true/g" $f
		sed $INPLACE_SED_FLAG "430,440s/enable = false/enable = true/g" $f
		# Enable prometheus
		sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/g" $f
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

	if [ X`curl localhost:26657/status | sed -n 's/\"catching_up\": \(true\|false\)/\1/p'` = Xtrue ]; then
		# in bash, 0 is true and 1 is false
		return 0
	fi
	return 1
}

heighest() {
	addrs=$1
	current="-1"
	oldIFS=$IFS
	IFS=","
	for addr in $addrs; do 
		a=`curl $addr:26657/status | sed -n 's/\"latest_block_height\": "\([0-9]*\)",/\1/p' | tr -d ' '`
		if [ $a -ge $current ]; then
			current=$a
		fi
	done
	IFS=$oldIFS
	echo $current
}

behind() {
	addr=$1
	heighest=$2
	a=`curl $addr:26657/status | sed -n 's/\"latest_block_height\": "\([0-9]*\)",/\1/p' | tr -d ' '`
	if [ $a -le `expr $heighest - 100` ]; then
		return 0
	fi
	return 1
}

while true; do
	ephemeral-configs `echo "$ADDRS"`
	ansible-playbook ./ansible/re-init-testapp.yaml -u root -i ./ansible/hosts --limit=ephemeral -e "testnet_dir=./rotating" -f 100

	# Wait for all of the ephemeral hosts to complete blocksync.
	oldIFS=$IFS
	IFS=","; for addr in $ADDRS; do
		IFS=$oldIFS
		while ! running $addr; do
			sleep 2
		done
	done
	h=$(heighest `ansible all --list-hosts -i ./ansible/hosts --limit validators | tail +2 | paste -s -d, | tr -d ' '`)
	IFS=","; for addr in $ADDRS; do
		IFS=$oldIFS
		while behind $addr $h; do
			sleep 2
		done
	done
	IFS=$oldIFS
done
