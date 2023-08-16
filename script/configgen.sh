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
			"port": 26657
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
IFD_PATH='./ifd.json'

ifd-from-ansible $HOSTS_PATH $IFD_PATH $VPC_SUBNET

cp -p ./testnet.toml ./ansible
rm -rf ./ansible/testnet
go run github.com/cometbft/cometbft/test/e2e/runner@$VERSION setup -f ./ansible/testnet.toml --infrastructure-type digital-ocean --infrastructure-data $IFD_PATH


for file in `find ./ansible/testnet/ -name config.toml -type f`; do
	sed $INPLACE_SED_FLAG "s/unsafe = .*/unsafe = true/g" $file
	sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/g" $file
	sed $INPLACE_SED_FLAG "s/cache_size = .*/cache_size = 200000/g" $file
done

mv $IFD_PATH ./ansible/testnet/infrastructure-data.json
