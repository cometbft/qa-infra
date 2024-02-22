#!/bin/bash
set -euo pipefail

# The functionality need from sed in this script is not covered by POSIX; it uses different syntax
# in gnu sed and in BSD sed.
# These helper variables have been introduced to deal with those differences.
# Moreover, sed's in place mode requires flag '-i ""' in BSD sed, which makes the use of 'eval'
# necessary every time 'sed -i' is called in order to re-interpret the flag's contents when stored
# in a variable.
INPLACE_SED_FLAG='-i'
SED_BW='\b' # No difference needed between beginning of word and end of word in Linux
SED_EW='\b'
if [[ $(uname) == "Darwin" ]]; then
	INPLACE_SED_FLAG='-i.bak'
	SED_BW='[[:<:]]' #Beginning of word in regex
	SED_EW='[[:>:]]' #End of word in regex
fi

# ifd-from-ansible is responsible for generating the 'infrastructure-data' that is
# read by the testnet generator tool.
ifd-from-ansible() {
	HOST_PATH=$1
	OUT_PATH=$2
	VPC_SUBNET=$3
	
	cat <<EOF > $OUT_PATH
{
	"provider": "digital-ocean",
	"network": "$VPC_SUBNET",
	"instances": {
EOF
	
	lines=`grep '^.*name=.*$' $HOST_PATH | tr " " : | sort | uniq`
	count=`echo "$lines" | wc -l`
	
	i=1
	for host in  $lines; do
		ext_ip=`echo $host | cut -d: -f1`
		ip=`echo $host | cut -d: -f3 | cut -d= -f2`
		name=`echo $host | cut -d: -f2 | sed -n 's/name=\(.*\)/\1/p'`
		cat <<EOF >> $OUT_PATH
		"$name": {
			"ext_ip_address": "$ext_ip",
			"ip_address": "$ip",
			"rpc_port": 26657
EOF
		if [ $i -lt $count ]; then
			cat <<EOF >> $OUT_PATH
		},
EOF
		else
			cat <<EOF >> $OUT_PATH
		}
EOF
		fi
		
		i=`expr $i + 1`
	done
	cat <<EOF >> $OUT_PATH
	}
}
EOF
}

VERSION=$1
HOSTS_PATH=$2
VPC_SUBNET=$3
MANIFEST=$4

TESTNET_DIR=./ansible/testnet
mkdir -p $TESTNET_DIR
IFD_PATH=$TESTNET_DIR/infrastructure-data.json

ifd-from-ansible $HOSTS_PATH $IFD_PATH $VPC_SUBNET

mkdir -p latency
curl -s https://raw.githubusercontent.com/cometbft/cometbft/$VERSION/test/e2e/pkg/latency/aws-latencies.csv > latency/aws-latencies.csv # needed in this directory to validate zones

go run github.com/cometbft/cometbft/test/e2e/runner@$VERSION setup \
	-f $MANIFEST --infrastructure-type digital-ocean --infrastructure-data $IFD_PATH \
	--testnet-dir $TESTNET_DIR

for file in `find $TESTNET_DIR -name config.toml -type f`; do
	sed $INPLACE_SED_FLAG "s/unsafe = .*/unsafe = true/" $file
	sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/" $file

	# to allow sending big txs via websockets
	sed $INPLACE_SED_FLAG "s/max_body_bytes = .*/max_body_bytes = 2097152/" $file
	sed $INPLACE_SED_FLAG "s/max_header_bytes = .*/max_header_bytes = 2097152/" $file
done
