#!/bin/bash
set -euo pipefail

NEW_IPS=$1

cat ./testnet.toml > ./full-testnet.toml
cat ./rotating.toml >> full-testnet.toml

go run github.com/tendermint/tendermint/test/e2e/runner@v0.35.5 setup -f full-testnet.toml
rm ./full-testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./full-testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | grep -v 'ephemeral' | sort -k1 | cut -d ' ' -f2`

while read old <&3 && read new <&4; do
	find ./full-testnet/ -type f | xargs -I{} sed -i "s/$old/$new/g" {}
done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' )

rm -rf ./ansible/full-testnet
mv ./full-testnet ./ansible
