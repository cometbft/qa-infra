#!/bin/sh
set -euo pipefail
i=`grep '\[node..*\]' ./testnet.toml | sed -e 's/\[node\.\(.*\)]/"\1"/' | sort`
name_list=`echo $i | tr ' ' ,`
cp tf/nodes.tf.tmpl tf/nodes.tf
sed -i "s/\[instance_names\]/\[$name_list\]/g" tf/nodes.tf
