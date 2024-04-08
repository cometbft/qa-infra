#!/usr/bin/env bash

set -e

SCRIPTS_COMMIT_HASH="e42f62b68" # v1.0.0-alpha.2

DIR=$1
START_TIME=$2
DURATION=$3
TEST_CASE=${4:-200_nodes}
RELEASE_NAME=${5:-"v1.0.0-alpha.2"} # name should not have spaces

[ ! -z "$START_TIME" ] && [ ! -z "$DURATION" ] || (echo -e "Error: not enough arguments.\nUsage: $0 <dir> <start_time> <duration> [<test_case>]"; exit 1) 
[ -d "$DIR" ] || (echo "Error: directory '$DIR' not found"; exit 1)
[ -d "$DIR/prometheus" ] || (echo "Error: directory '$DIR/prometheus' not found"; exit 1)

echo Check that a Prometheus server is running
curl -s localhost:9090/status > /dev/null || (echo "Prometheus server is not running in localhost:9090; try with `dirname $0`/prometheus-start-local.sh $DIR"; exit 1)

pushd "$DIR"

if [ ! -f "prometheus_plotter.py" ]; then
    echo Download scripts...
    curl -s https://raw.githubusercontent.com/cometbft/cometbft/$SCRIPTS_COMMIT_HASH/scripts/qa/reporting/prometheus_plotter.py > prometheus_plotter.py
fi

echo Setup virtual environment...
python3 -m venv .venv && source .venv/bin/activate

echo Install dependencies...
pip install requests matplotlib pandas prometheus-pandas

echo python3 prometheus_plotter.py $RELEASE_NAME $START_TIME $DURATION $TEST_CASE
python3 prometheus_plotter.py $RELEASE_NAME $START_TIME $DURATION $TEST_CASE

deactivate
popd
echo Done ✅
