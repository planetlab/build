#!/bin/sh

make stage1=true PLDISTRO=mlab
make iptables
./rebuild-bootcd.sh
make
