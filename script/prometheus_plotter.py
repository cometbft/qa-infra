# pip install numpy pandas matplotlib requests 

import sys
import os

import matplotlib as mpl
import matplotlib.pyplot as plt

import numpy as np 
import pandas as pd 

import requests 
from urllib.parse import urljoin

from prometheus_pandas import query

release = 'v0.34.27'
path = os.path.join('imgs','cmt2tm1')
prometheus = query.Prometheus('http://localhost:9090')

# Do prometheus queries
queries = [ 
    (( 'cometbft_p2p_peers', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'peers', 'Peers', 'time (s)'),
    (( 'cometbft_mempool_size', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'mempool_size', 'TXs', 'time (s)'),
    (( 'avg(cometbft_mempool_size)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'avg_mempool_size', 'TXs', 'time (s)'),
    (( 'cometbft_consensus_rounds', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'rounds', '# Rounds', 'time (s)'),
    (( 'cometbft_consensus_height', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'blocks', '# Blocks', 'time (s)'), 
    (( 'rate(cometbft_consensus_height[1m])*60', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'block_rate', 'Blocks/s', 'time (s)'),
    (( 'cometbft_consensus_total_txs', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'total_txs', '# TXs', 'time (s)'),
    (( 'rate(cometbft_consensus_total_txs[1m])*60', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'total_txs_rate', 'TXs/s', 'time (s)'),
    (( 'process_resident_memory_bytes', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'memory', 'Bytes', 'time (s)'),
    (( 'avg(process_resident_memory_bytes)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'avg_memory', 'Bytes', 'time (s)'),
    (( 'process_cpu_seconds_total', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'cpu', 'CPU Time', 'time (s)'), 
    (( 'avg(process_cpu_seconds_total)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'), 'avg_cpu', 'CPU Time', 'time (s)'),
]

for (query, file_name, yaxis, xaxis)  in queries:
    print(query)

    data_frame = prometheus.query_range(*query)
    data_frame = data_frame.set_index(pd.to_timedelta(data_frame.index.strftime('%H:%M:%S')))
    print(data_frame.index)

    data_frame.plot(figsize=(10,6), grid=True, xlabel=xaxis, ylabel=yaxis, title=query[0], legend=False)
    #plt.figure(figsize=(10,6))
    #plt.plot(data_frame)
    #plt.ylabel(yaxis)
    #plt.xlabel(xaxis)
    #plt.title(query[0])
    #plt.grid(True)


    plt.savefig(os.path.join(path, file_name + '.png'))
    plt.show()

