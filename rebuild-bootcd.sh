#!/bin/sh

make bootcd-clean
make bootcdR420-clean
make bootcdR630-clean

make bootcd-source
make bootcdR420-source
make bootcdR630-source

cp /build/mirroring/centos6/yum.repos.d/building.repo.in MODULES/build/mirroring/centos6/yum.repos.d/
cp /build/config.mlab/mlab.mirrors MODULES/build/config.mlab/
cp /build/config.mlab/yumexclude.pkgs MODULES/build/config.mlab/yumexclude.pkgs

make bootcd
make bootcdR420
make bootcdR630
