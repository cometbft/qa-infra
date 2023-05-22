#!/bin/bash

set -euo pipefail

ADDR="" # Some full node

/root/go/bin/load -c 4 -T 14400 -r 800 -s 1024 --broadcast-tx-method sync --endpoints "ws://$ADDR:26657/websocket"
