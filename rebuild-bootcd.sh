#!/bin/sh

make bootcd-clean
make bootcd-source

cp /build/mirroring/centos6/yum.repos.d/building.repo.in MODULES/build/mirroring/centos6/yum.repos.d/
cp /build/config.mlab/mlab.mirrors MODULES/build/config.mlab/
cp /build/config.mlab/yumexclude.pkgs MODULES/build/config.mlab/yumexclude.pkgs
make bootcd
