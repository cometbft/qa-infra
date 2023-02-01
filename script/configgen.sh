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
	
	cat <<EOF > $OUT_PATH
{
	"provider": "digital-ocean",
	"network": "0.0.0.0/0",
	"instances": {
EOF
	
	lines=`grep '^.*name=.*$' $HOST_PATH | tr " " : | sort | uniq`
	count=`echo "$lines" | wc -l`
	
	i=1
	for host in  $lines; do
		ip=`echo $host | cut -d: -f1`
		name=`echo $host | cut -d: -f2 | sed -n 's/name=\(.*\)/\1/p'`
		cat <<EOF >> $OUT_PATH
		"$name": {
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
IFD_PATH='./ifd.json'

ifd-from-ansible $HOSTS_PATH $IFD_PATH

go run github.com/cometbft/cometbft/test/e2e/runner@$VERSION setup -f ./testnet.toml --infrastructure-type digital-ocean --infrastructure-data ./ifd.json


for file in `find ./testnet/ -name config.toml -type f`; do
	sed $INPLACE_SED_FLAG "s/unsafe = .*/unsafe = true/g" $file
	sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/g" $file
done

rm -rf ./ansible/testnet
mv ./testnet ./ansible
mv $IFD_PATH ./ansible/testnet/infrastructure-data.json
