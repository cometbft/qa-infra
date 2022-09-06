#!/bin/bash
set -euo pipefail

VERSION=$1
NEW_IPS=$2

go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

while read old <&3 && read new <&4; do
	find ./testnet/ -type f | xargs -I{} sed -i="" "s/$old/$new/g" {}
done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' ) 

rm -rf ./ansible/testnet
mv ./testnet ./ansible
