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
prometheus = query.Prometheus('http://localhost:9090')

# Do prometheus queries
queries = [ 
    ( 'cometbft_p2p_peers', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'cometbft_mempool_size', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'avg(cometbft_mempool_size)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'cometbft_consensus_rounds', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'cometbft_consensus_height', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'rate(cometbft_consensus_height[1m])*60', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'cometbft_consensus_total_txs', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'rate(cometbft_consensus_total_txs[1m])*60', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'process_resident_memory_bytes', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'avg(process_resident_memory_bytes)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'process_cpu_seconds_total', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
    ( 'avg(process_cpu_seconds_total)', '2023-02-08T13:09:20Z', '2023-02-08T13:14:20Z', '1s'),
]

for query in queries:
    print(query)
    data_frame = prometheus.query_range(*query)

    #plt.ylabel(
    #plt.xlabel(
    plt.title(query[0])
    plt.grid(True)

    plt.plot(data_frame)

    plt.savefig(query[0]+'.png')
    plt.show()
    plt.clf()

