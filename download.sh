#!/bin/bash
echo "Starting donwload rom and auto run bhlnk script"
wget -q $1
./bhlnk.sh
