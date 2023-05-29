#!/bin/bash

set -euo pipefail

CONNS=(1 2 4)
RATES=(200 400 800 1600)
ADDR=127.0.0.1 # Fill in with the IP address of a node to target

mempoolfull() {
	if [ `curl -s "http://$ADDR:26657/num_unconfirmed_txs" | jq .result.n_txs | tr -d '"'` ]; then
		return 1
	fi
	return 0
}

for conn in ${CONNS[@]}; do
	for rate in ${RATES[@]}; do
		echo "Conns: $conn, Rate: $rate"
		/root/go/bin/load -c $conn -T 90 -r $rate -s 1024 --broadcast-tx-method sync --endpoints "ws://$ADDR:26657/websocket"
		while mempoolfull; do
			sleep 5;
		done
		sleep `expr 120 + $rate / 60`;
	done
done
echo "Experiments Complete"
echo
