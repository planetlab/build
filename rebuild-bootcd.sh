#!/bin/sh

make bootcd-clean
make bootcd-source

cp building.repo.in MODULES/build/mirroring/centos6/yum.repos.d/building.repo.in
cp build.common MODULES/build/build.common
cp config.mlab/yumexclude.pkgs MODULES/build/config.mlab/yumexclude.pkgs
make bootcd
