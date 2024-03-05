#!bin/bash

echo 'vote_extensions_enable_height = 1'

echo '
[node.seed0] 
mode = "seed" 
persistent_peers = ["seed1", "seed2", "seed3", "seed4"]
[node.seed1]
mode = "seed"
persistent_peers = ["seed0", "seed2", "seed3", "seed4"]
[node.seed2]
mode = "seed"
persistent_peers = ["seed1", "seed0", "seed3", "seed4"]
[node.seed3]
mode = "seed"
persistent_peers = ["seed1", "seed2", "seed0", "seed4"]
[node.seed4]
mode = "seed"
persistent_peers = ["seed1", "seed2", "seed3", "seed0"]

[node.full00]
mode = "full"
seeds = ["seed0"]
[node.full01]
mode = "full"
seeds = ["seed1"]
[node.full02]
mode = "full"
seeds = ["seed2"]
[node.full03]
mode = "full"
seeds = ["seed3"]
[node.full04]
mode = "full"
seeds = ["seed4"]
[node.full05]
mode = "full"
seeds = ["seed0"]
[node.full06]
mode = "full"
seeds = ["seed1"]
[node.full07]
mode = "full"
seeds = ["seed2"]
[node.full08]
mode = "full"
seeds = ["seed3"]
[node.full09]
mode = "full"
seeds = ["seed4"]
[node.full10]
mode = "full"
seeds = ["seed0"]
[node.full11]
mode = "full"
seeds = ["seed1"]
[node.full12]
mode = "full"
seeds = ["seed2"]
[node.full13]
mode = "full"
seeds = ["seed3"]
[node.full14]
mode = "full"
seeds = ["seed4"]
[node.full15]
mode = "full"
seeds = ["seed0"]
[node.full16]
mode = "full"
seeds = ["seed1"]
[node.full17]
mode = "full"
seeds = ["seed2"]
[node.full18]
mode = "full"
seeds = ["seed3"]
[node.full19]
mode = "full"
seeds = ["seed4"]
'

for x in {0..174}; do 
tmp=$((x % 6)) 
echo -e "\n"
if [[ $x -lt 10 ]]; then
echo "[node.validator00"$x"]" 
fi; 

if [[ $x -ge 10 && $x -lt 100 ]]; then
echo "[node.validator0"$x"]" 
fi; 

if [[ $x -ge 100 ]]; then
echo "[node.validator"$x"]" 
fi; 

#no pruning old layout
if [[ $tmp -eq 0 ]]; then 
echo '#no pruning old layout'
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'seeds = ["seed0"]'
fi; 

# pruning + compaction new layout
if [[ $tmp -eq 1 ]]; then 
echo '# pruning + compaction new layout'
echo 'db_key_layout_version = "v2"' 
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'retain_blocks = 100'
echo 'compaction_interval = 200'
echo 'compact = true'
echo 'seeds = ["seed1"]'
fi; 


# pruning no compaction new layout
if [[ $tmp -eq 2 ]]; then
echo "# pruning no compaction new layout" 
echo 'db_key_layout_version = "v2"' 
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'retain_blocks = 100'
echo 'seeds = ["seed2"]'
fi; 

# no pruning new layout
if [[ $tmp -eq 3 ]]; then 
echo '# no pruning new layout'
echo 'db_key_layout_version = "v2"' 
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'seeds = ["seed3"]'
fi; 



if [[ $tmp -eq 4 ]]; then 
echo "# pruning no compaction old layout"
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'retain_blocks = 100'
echo 'seeds = ["seed4"]'
fi; 


if [[ $tmp -eq 5 ]]; then 
echo "# pruning + compaction old layout"
echo "discard_abci_responses = true"
echo 'indexer = "null"'
echo 'retain_blocks = 100'
echo 'compaction_interval = 200'
echo 'compact = true'
echo 'seeds = ["seed0"]'
fi; 

done