#!/bin/bash
echo "Starting donwload rom and auto run bhlnk script"
wget $1
./bhlnk.sh
