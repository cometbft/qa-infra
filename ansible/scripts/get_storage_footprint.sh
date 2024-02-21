#!/bin/bash

CMT_HOME=$1

if [ -z "${CMT_HOME}" ]; then
CMT_HOME="/root/.testapp"
fi 

while true ; do du -m $CMT_HOME/data | tee -a $CMT_HOME/folder_size.log ; sleep 10 ; done
