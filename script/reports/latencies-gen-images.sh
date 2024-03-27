#!/usr/bin/env bash

set -e

DIR=$1
RELEASE_NAME=${2:-v1.0.0-alpha.2}
CSV_PATH=${3:-results/raw.csv}
COMET_COMMIT_HASH=${3:-e42f62b68} # v1.0.0-alpha.2

[ -d "$DIR" ] || (echo "Error: directory '$DIR' not found"; exit 1)

pushd "$DIR"
 
if [ ! -d "$DIR/blockstore.db" ]; then
    echo unzip blockstore.db.zip...
    unzip -n blockstore.db.zip
fi

mkdir -p results
if [ -f "results/raw.csv" ]; then
    echo Generate results/raw.csv...
    go run github.com/cometbft/cometbft/test/loadtime/cmd/report@$COMET_COMMIT_HASH --database-type goleveldb --data-dir ./ --csv results/raw.csv
fi

if [ -f "latency_throughput.py" ]; then
    echo Download latency_throughput.py...
    curl -s https://raw.githubusercontent.com/cometbft/cometbft/$COMET_COMMIT_HASH/scripts/qa/reporting/latency_throughput.py > latency_throughput.py
fi

if [ -f "latency_plotter.py" ];
    echo Download latency_plotter.py...
    curl -s https://raw.githubusercontent.com/cometbft/cometbft/$COMET_COMMIT_HASH/scripts/qa/reporting/latency_plotter.py > latency_plotter.py
fi

echo Setup Python virtual environment...
python3 -m venv .venv && source .venv/bin/activate

echo Install dependencies...
pip install pandas matplotlib 

echo Generating latency/throughput image...
python3 latency_throughput.py -t 'CometBFT: Latency vs Throughput' latency_throughput_$RELEASE_NAME.png results/raw.csv

echo latency_plotter.py $RELEASE_NAME $CSV_PATH
python3 latency_plotter.py $RELEASE_NAME $CSV_PATH

deactivate
popd
echo Done ✅
