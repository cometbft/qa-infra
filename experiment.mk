# Take care to make these values unique between experiments running
# on the same DigitalOcean project.
DO_INSTANCE_TAGNAME=main-testnet
DO_VPC_SUBNET=172.19.144.0/20

EPHEMERAL_SIZE ?= 0

LOAD_CONNECTIONS ?= 2
LOAD_TX_RATE ?= 200
LOAD_TOTAL_TIME ?= 91
ITERATIONS ?= 5
