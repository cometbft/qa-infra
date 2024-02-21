#!/bin/bash

while true ; do du -m /root/.testapp/data | tee -a /root/.testapp/folder_size.log ; sleep 10 ; done
