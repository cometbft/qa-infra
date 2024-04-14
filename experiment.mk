# Take care to make these values unique between experiments running
# on the same DigitalOcean project.
DO_INSTANCE_TAGNAME=main-testnet-lasaro
DO_VPC_SUBNET=172.31.240.0/20

MANIFEST ?= ./testnet.toml
MANIFEST_PATH=$(shell realpath $(MANIFEST))

VERSION_TAG ?= 72450bc82902c8c3f5995da116454c067c0d3373 
#VERSION_TAG ?= 3b783434f #v0.34.27 (cometbft/cometbft)
#VERSION_TAG ?= bef9a830e  #v0.37.alpha3 (cometbft/cometbft)
#VERSION_TAG ?= v0.38.0-alpha.2
#VERSION_TAG ?= e9abb116e #v0.38.alpha2 (cometbft/cometbft)

VERSION_WEIGHT ?= 1

## For testnets that mix nodes running different versions of CometBFT.
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION2_WEIGHT ?= 0

EPHEMERAL_SIZE ?= 0
#EPHEMERAL_SIZE ?= 25

LOAD_CONNECTIONS ?= 2
LOAD_TX_RATE ?= 200
LOAD_TOTAL_TIME ?= 91
ITERATIONS ?= 5
