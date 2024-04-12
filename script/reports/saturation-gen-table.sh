#!/usr/bin/env bash

set -e

DIR=$1
COMET_COMMIT_HASH=${2:-e42f62b68} # v1.0.0-alpha.2

[ -d "$DIR" ] || (echo "Error: directory '$DIR' not found"; exit 1)

pushd "$DIR"

if [ ! -d "blockstore.db" ]; then
    [ -f "blockstore.db.zip" ] || (echo "Error: file '$DIR/blockstore.db.zip' not found"; exit 1)
    echo unzip blockstore.db.zip...
    unzip -n blockstore.db.zip
fi

mkdir -p results

echo Generating saturation table...

# File `report.txt` contains an unordered list of experiments with varying concurrent connections
# and transaction rate. We will need to separate the data per experiment.
[ -f results/report.txt ] || go run github.com/cometbft/cometbft/test/loadtime/cmd/report@$COMET_COMMIT_HASH --database-type goleveldb --data-dir ./ > results/report.txt

# Copy each experiment in `report.txt` into corresponding files `report<c>.txt`, where `c` is the
# number of connections in the experiment. It is expected that experiments are sorted in ascending
# tx rate order.
for c in 1 2 4; do 
    echo "$c"
    file="results/report$c.txt"
    res=`grep -s "Connections: $c" results/report.txt -B 2 -A 10` || true
    if [ "$res" != "" ]; then 
        echo "$res" > $file
        # Replace tabs by spaces in all column files.
        sed -i.bak 's/\t/    /g' $file
    fi
done

# Generate `report_tabbed.txt` containing the results in matrix format. If the experiments use only
# one connection, just copy the report to the final file. Otherwise, generate the matrix file by
# putting the contents of `report<c>.txt` side by side. This effectively creates a table where rows
# are a particular tx rate and columns are a particular number of websocket connections.
if [ -f results/report2.txt ] && [ -f results/report4.txt ]; then 
    # Combine the column files into a single table file. And merge the new column files into one.
    paste results/report1.txt results/report2.txt results/report4.txt | column -s $'\t' -t > report_tabbed.txt
else
    cp results/report.txt report_tabbed.txt
fi

# Keep just the number of processed transactions in `saturation_table.tsv`.
sed -i.bak 's/\t/    /g' report_tabbed.txt
cat report_tabbed.txt | grep 'Valid Tx' | sed 's/Total Valid Tx://g' | tr -s ' ' > saturation_table.tsv

popd
echo Done ✅
