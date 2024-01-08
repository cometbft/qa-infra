EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=main-testnet

LOAD_CONNECTIONS ?= 2
LOAD_TX_RATE ?= 200
LOAD_TOTAL_TIME ?= 91
ITERATIONS ?= 5

# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any

VERSION_TAG ?= 9ab4018a0f96b9144d9e2c0194d34596a8906627 # bucky limited concurrency
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION_WEIGHT ?= 1
VERSION2_WEIGHT ?= 0
