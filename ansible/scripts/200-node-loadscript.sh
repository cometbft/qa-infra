#!/bin/bash

## Set of test instances for finding the saturation point of the network.

set -euo pipefail

RATES=(100 200 300 400 500 600 700 800 900 1000)
ADDR=${1:-"127.0.0.1"} # Fill in with the IP address of a node to target

mempoolfull() {
	if [ `curl -s "http://$ADDR:26657/v1/num_unconfirmed_txs" | jq .result.n_txs | tr -d '"'` ]; then
		return 1
	fi
	return 0
}

for rate in ${RATES[@]}; do
	echo "Rate: $rate tx/s"
	/root/go/bin/load -c 1 -T 181 -r $rate -s 1024 --broadcast-tx-method sync --endpoints "ws://$ADDR:26657/v1/websocket"
	while mempoolfull; do
		sleep 5;
	done
	sleep `expr 120 + $rate / 60`;
done

echo "Experiments Complete"
echo
