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

VERSION=$1
NEW_IPS=$2
SEED_IPS=$3

go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g' | sed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

for file in `find ./testnet/ -name config.toml -type f`; do
	while read old <&3 && read new <&4; do
		sed $INPLACE_SED_FLAG "s/$SED_BW$old$SED_EW/$new/g" $file
	done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' )
	sed $INPLACE_SED_FLAG "s/unsafe = .*/unsafe = true/g" $file
	sed $INPLACE_SED_FLAG "s/prometheus = .*/prometheus = true/g" $file
done

# Seed nodes end up with many outgoing persistent peers. Tendermint has an
# Upperbound on how many persistent peers it can have. We reduce the set of persistent
# peers here to just the fellow seeds to not run afoul of this limit.
seedsSlashSeparated=`echo $SEED_IPS | sed 's/,/\\\|/g'`
for fname in `find . -path './testnet/seed*' -type f -name config.toml`; do
	persistentPeers=`sed -rn 's/persistent_peers = "(.*)"/\1/p' $fname \
		| tr , '\n' \
		| grep "\($seedsSlashSeparated\)" || true`

	result=`echo "$persistentPeers" | paste -s -d, -`
	replace_str="s/persistent_peers = .*/persistent_peers = \\\"$result\\\"/g"
	sed $INPLACE_SED_FLAG "$replace_str" $fname
done

rm -rf ./ansible/testnet
mv ./testnet ./ansible
