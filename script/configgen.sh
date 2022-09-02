#!/bin/bash
set -euo pipefail

NEW_IPS=$1
SEED_IPS=$2

go run github.com/tendermint/tendermint/test/e2e/runner@v0.35.9 setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

while read old <&3 && read new <&4; do
	find ./testnet/ -type f -name config.toml | xargs -I{} sed -i "s/$old\(\b\)/$new\1/g" {}
done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' )

for fname in `find . -path './testnet/*' -type f -name config.toml`; do
	sed -i "s/queue-type =.*/queue-type = \"simple-priority\"/g" $fname
done

seedsSlashSeparated=`echo $SEED_IPS | sed 's/,/\\\|/g'`
for fname in `find . -path './testnet/seed*' -type f -name config.toml`; do
	persistentPeers=`sed -rn 's/persistent-peers = "(.*)"/\1/p' $fname \
		| tr , '\n' \
		| grep "\($seedsSlashSeparated\)" || true`

	result=`echo "$persistentPeers" | paste -s -d,`
	sed -i "s/persistent-peers = .*/persistent-peers = \"$result\"/g" $fname
	sed -i 's/max-connections =.*/max-connections = 200/g' $fname
	sed -i 's/max-outgoing-connections =.*/max-outgoing-connections = 35/g' $fname
done

rm -rf ./ansible/testnet
mv ./testnet ./ansible
