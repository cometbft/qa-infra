#!/bin/bash
set -euo pipefail

find ./ansible/testnet/ -type f -name config.toml | xargs -I{} sed -i "s/max-connections = .*/max-connections = 64/g" {}
