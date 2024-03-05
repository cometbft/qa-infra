# Take care to make these values unique between experiments running
# on the same DigitalOcean project.
DO_INSTANCE_TAGNAME=storage-testnet
DO_VPC_SUBNET=172.19.144.0/20

MANIFEST ?= ./testnets/storage_example.toml
MANIFEST_PATH=$(shell realpath $(MANIFEST))

VERSION_TAG ?= 2a3315af09065f44653519b4a72f0bfda3422e9c # tag of jasmina/1041-support-for-two-key-layouts 05.03.2024
#VERSION_TAG ?= 3b783434f #v0.34.27 (cometbft/cometbft)
#VERSION_TAG ?= bef9a830e  #v0.37.alpha3 (cometbft/cometbft)
#VERSION_TAG ?= v0.38.0-alpha.2
#VERSION_TAG ?= e9abb116e #v0.38.alpha2 (cometbft/cometbft)

VERSION_WEIGHT ?= 1

## For testnets that mix nodes running different versions of CometBFT.
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION2_WEIGHT ?= 0

EPHEMERAL_SIZE ?= 0

LOAD_CONNECTIONS ?= 2
LOAD_TX_RATE ?= 4000
LOAD_TOTAL_TIME ?= 1800
ITERATIONS ?= 1
