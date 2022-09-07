#!/bin/bash
set -euo pipefail

INPLACE_SED_FLAG='-i=""'
if sed --version | head -1 | grep GNU; then
	INPLACE_SED_FLAG='-i'
fi

VERSION=$1
NEW_IPS=$2
SEED_IPS=$3

go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

while read old <&3 && read new <&4; do
	find ./testnet/ -type f | xargs -I{} sed $INPLACE_SED_FLAG "s/$old/$new/g" {}
done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' ) 


# Seed nodes end up with many outgoing persistent peers. Tendermint has an
# Upperbound on how many persistent peers it can have. We reduce the set of persistent
# peers here to just the fellow seeds to not run afoul of this limit.
seedsSlashSeparated=`echo $SEED_IPS | sed 's/,/\\\|/g'`
for fname in `find . -path './testnet/seed*' -type f -name config.toml`; do
	persistentPeers=`sed -rn 's/persistent_peers = "(.*)"/\1/p' $fname \
		| tr , '\n' \
		| grep "\($seedsSlashSeparated\)" || true`

	result=`echo "$persistentPeers" | paste -s -d, -`
	sed $INPLACE_SED_FLAG "s/persistent_peers = .*/persistent-peers = \"$result\"/g" $fname
done

rm -rf ./ansible/testnet
mv ./testnet ./ansible
