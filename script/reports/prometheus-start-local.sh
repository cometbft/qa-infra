#!/usr/bin/env bash

# This script starts a Prometheus server taking the data and configuration (prometheus.yml file)
# found in a given directory (usually a directory with data from experiments). If there's no data
# but it founds a prometheus.zip file, it will first unzip it. If there's another Prometheus
# instance running, it will kill it first.

set -e

DIR=$1
[ -d "$DIR" ] || (echo "Error: directory '$DIR' not found"; exit 1)

CONFIG_FILE="$DIR/prometheus.yml"
[ -f $CONFIG_FILE ] || (echo "Error: file '$CONFIG_FILE' not found"; exit 1)

if [ ! -d "$DIR/prometheus" ]; then
    ZIP_FILE="$DIR/prometheus.zip"
    [ -f $ZIP_FILE ] || (echo "Error: file '$ZIP_FILE' not found"; exit 1)
    
    pushd "$DIR"
    echo unzip $ZIP_FILE...
    unzip -n `basename $ZIP_FILE`
    popd
fi

# Kill any existing Prometheus server
pkill -f prometheus &> /dev/null || true

# Start Prometheus
nohup prometheus --storage.tsdb.path $DIR/prometheus/ --config.file=$CONFIG_FILE &
PROMETHEUS_PID=$!
echo Started Prometheus with PID $PROMETHEUS_PID
