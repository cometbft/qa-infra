# Take care to make these values unique between experiments running
# on the same DigitalOcean project.
DO_INSTANCE_TAGNAME=main-testnet
DO_VPC_SUBNET=172.19.144.0/20

MANIFEST ?= ./testnets/example.toml
MANIFEST_PATH=$(shell realpath $(MANIFEST))

VERSION_TAG ?= f92bace91 # tag of main on 05.02.2024
#VERSION_TAG ?= 3b783434f #v0.34.27 (cometbft/cometbft)
#VERSION_TAG ?= bef9a830e  #v0.37.alpha3 (cometbft/cometbft)
#VERSION_TAG ?= v0.38.0-alpha.2
#VERSION_TAG ?= e9abb116e #v0.38.alpha2 (cometbft/cometbft)

VERSION_WEIGHT ?= 1

## For testnets that mix nodes running different versions of CometBFT.
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION2_WEIGHT ?= 0

EPHEMERAL_SIZE ?= 0

LOAD_CONNECTIONS ?= 1
LOAD_TX_RATE ?= 400
LOAD_TOTAL_TIME ?= 181
ITERATIONS ?= 5
