#!/bin/sh
set -euo pipefail

NEW_IPS=$1
TMPDIR=`mktemp -d`

cat << EOF > $TMPDIR/testnet.yaml
disable_legacy_p2p = false 
initial_height = 1

EOF

NUM_IPS=`echo $NEW_IPS | tr , '\n' | wc -l`

m=`expr $NUM_IPS - 1`
for i in `seq 0 $m`; do
	echo [node.validator$i] >> $TMPDIR/testnet.yaml
done

go run github.com/tendermint/tendermint/test/e2e/runner@v0.35.5 setup -f $TMPDIR/testnet.yaml
IPS=`grep -E '(ipv4_address)' $TMPDIR/testnet/docker-compose.yml | sed 's/^.*ipv4_address: \(.*\)/\1/g'`


rm $TMPDIR/testnet/docker-compose.yml
while read old <&3 && read new <&4; do
	find $TMPDIR/testnet/ -type f | xargs -I{} sed -i "s/$old/$new/g" {}
done 3< <(echo $IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' ) 
 

rm -rf ansible/testnet-configs
mv $TMPDIR/testnet ansible/testnet-configs
rm -rf $TMPDIR
