EPHEMERAL_SIZE ?= 0
DO_INSTANCE_TAGNAME=v039-cat-lasaro
DO_VPC_SUBNET=172.19.144.0/20

LOAD_CONNECTIONS ?= 1
LOAD_TX_RATE ?= {{LOAD_TX_RATE}}
LOAD_TX_COUNT ?= 100000
LOAD_TOTAL_TIME ?= 601
ITERATIONS ?= 5


# Set it to "all" to retrieve from all hosts
# Set it to "any" to retrieve from one full node
# Set it to the exact name of a validator to retrieve from it
RETRIEVE_TARGET_HOST ?= any

VERSION_TAG ?= 47ffd93c4913c5212d87074939d9869e035e9f43 #skip + sleep + cat + limited
#VERSION2_TAG ?= 66c2cb634 #v0.34.26 (informalsystems/tendermint)
VERSION_WEIGHT ?= 2
VERSION2_WEIGHT ?= 0
