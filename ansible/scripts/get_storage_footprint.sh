#!/bin/bash

CMT_HOME=$1

if [ -z "${CMT_HOME}" ]; then
echo "CMT_HOME is not set, setting it to /root/.testapp"
CMT_HOME="/root/.testapp"
fi 

while true ; do du -m $CMT_HOME/data | tee -a $CMT_HOME/folder_size.log ; sleep 10 ; done
