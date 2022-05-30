#!/bin/sh
set -euo pipefail

size=$1

touch testnet.toml
echo "disable_legacy_p2p = false" > testnet.toml
echo "initial_height = 1" >> testnet.toml
echo  >> testnet.toml

for i in `seq 1 $size`; do
	echo [node.validator$i] >> testnet.toml
done

rm -rf ansible/testnet-configs
go run github.com/tendermint/tendermint/test/e2e/runner@v0.35.5 setup -f testnet.toml
mv testnet ansible/testnet-configs
rm ansible/testnet-configs/docker-compose.yml
