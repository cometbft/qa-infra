EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=comet-experiment

LOAD_CONNECTIONS ?= 1
LOAD_TX_RATE ?= 400
LOAD_TX_COUNT ?= 100000
LOAD_TOTAL_TIME ?= 201
ITERATIONS ?= 3


# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any

VERSION_TAG ?= v0.38.x
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION_WEIGHT ?= 1
VERSION2_WEIGHT ?= 0
