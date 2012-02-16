#
# declare the packages to be built and their dependencies
# initial version from Mark Huang
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
# rewritten by Thierry Parmentelat - INRIA Sophia Antipolis
#
# see doc in Makefile  
#

#
# kernel
#
# use a package name with srpm in it:
# so the source rpm is created by running make srpm in the codebase
#

# rebuild kernel-3.1 on fedora14 due to instabilities of the stock kernel
ifeq "$(DISTRONAME)" "f14"
kernel-MODULES := linux-3
kernel-SPEC := kernel-3.1.spec
kernel-DEVEL-RPMS += gettext elfutils-devel
kernel-BUILD-FROM-SRPM := yes
ifeq "$(HOSTARCH)" "i386"
kernel-RPMFLAGS:= --target i686 --with firmware
else
kernel-RPMFLAGS:= --target $(HOSTARCH) --with firmware
endif
kernel-SPECVARS += kernelconfig=planetlab
KERNELS += kernel

kernels: $(KERNELS)
kernels-clean: $(foreach package,$(KERNELS),$(package)-clean)

ALL += $(KERNELS)
# this is to mark on which image a given rpm is supposed to go
IN_BOOTCD += $(KERNELS)
IN_SLIVER += $(KERNELS)
IN_BOOTSTRAPFS += $(KERNELS)
endif

#
# NodeUpdate
#
nodeupdate-MODULES := nodeupdate
nodeupdate-SPEC := NodeUpdate.spec
ALL += nodeupdate
IN_BOOTSTRAPFS += nodeupdate

#
# ipod
#
ipod-MODULES := PingOfDeath
ipod-SPEC := ipod.spec
ALL += ipod
IN_BOOTSTRAPFS += ipod

#
# NodeManager
#
nodemanager-MODULES := nodemanager
nodemanager-SPEC := NodeManager.spec
ALL += nodemanager
IN_BOOTSTRAPFS += nodemanager

#
# pl_sshd
#
sshd-MODULES := pl_sshd
sshd-SPEC := pl_sshd.spec
ALL += sshd
IN_BOOTSTRAPFS += sshd

#
# codemux: Port 80 demux
#
codemux-MODULES := codemux
codemux-SPEC   := codemux.spec
ALL += codemux
IN_BOOTSTRAPFS += codemux

#
# fprobe-ulog
#
fprobe-ulog-MODULES := fprobe-ulog
fprobe-ulog-SPEC := fprobe-ulog.spec
ALL += fprobe-ulog
IN_BOOTSTRAPFS += fprobe-ulog

#
# libvirt
#
libvirt-MODULES := libvirt
libvirt-SPEC    := libvirt.spec
libvirt-BUILD-FROM-SRPM := yes
libvirt-DEVEL-RPMS += libxml2-devel gnutls-devel device-mapper-devel yajl-devel gettext 
libvirt-DEVEL-RPMS += python-devel libcap-ng-devel libpciaccess-devel radvd numactl-devel 
libvirt-DEVEL-RPMS += xhtml1-dtds libxslt libtasn1-devel systemtap-sdt-devel iptables-ipv6 augeas 
libvirt-DEVEL-RPMS += libudev-devel
libvirt-RPMFLAGS := --without storage-disk --without storage-iscsi --without storage-scsi \
	                --without storage-fs --without storage-lvm \
	                --without polkit --without sasl --without audit --with capng --with udev \
	                --without netcf --without avahi --without sanlock \
	                --without xen --without qemu --without hyperv --without phyp --without esx \
	                --without libxl \
	                --define 'packager PlanetLab'
ALL += libvirt
IN_NODEREPO += libvirt
IN_BOOTSTRAPFS += libvirt

#
# DistributedRateLimiting
#
#DistributedRateLimiting-MODULES := DistributedRateLimiting
#DistributedRateLimiting-SPEC := DistributedRateLimiting.spec
#ALL += DistributedRateLimiting
#IN_NODEREPO += DistributedRateLimiting

#
# pf2slice
#
pf2slice-MODULES := pf2slice
pf2slice-SPEC := pf2slice.spec
ALL += pf2slice

##
## PlanetLab Mom: Cleans up your mess
##
#mom-MODULES := Mom
#mom-SPEC := pl_mom.spec
#ALL += mom
#IN_BOOTSTRAPFS += mom

#
# inotify-tools - local import
# rebuild this on centos5 (not found) - see kexcludes in build.common
#
local_inotify_tools=false
ifeq "$(DISTRONAME)" "centos5"
local_inotify_tools=true
endif

ifeq "$(DISTRONAME)" "sl6"
local_inotify_tools=true
endif

ifeq "$(local_inotify_tools)" "true"
inotify-tools-MODULES := inotify-tools
inotify-tools-SPEC := inotify-tools.spec
inotify-tools-BUILD-FROM-SRPM := yes
IN_BOOTSTRAPFS += inotify-tools
ALL += inotify-tools
endif

#
# openvswitch
#
openvswitch-MODULES := openvswitch
openvswitch-SPEC := openvswitch.spec
openvswitch-DEPEND-DEVEL-RPMS += kernel-devel
#IN_BOOTSTRAPFS += openvswitch
#ALL += openvswitch

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
# ocaml-docs is not needed anymore but keep it on a tmp basis as some tags may still have it
vsys-DEVEL-RPMS += ocaml-ocamldoc ocaml-docs
ifeq "$(local_inotify_tools)" "true"
vsys-DEPEND-DEVEL-RPMS += inotify-tools inotify-tools-devel
endif
IN_BOOTSTRAPFS += vsys
ALL += vsys

#
# vsyssh : installed in slivers
#
vsyssh-MODULES := vsys
vsyssh-SPEC := vsyssh.spec
IN_SLIVER += vsyssh
ALL += vsyssh

#
# vsys-scripts
#
vsys-scripts-MODULES := vsys-scripts
vsys-scripts-SPEC := vsys-scripts.spec
IN_BOOTSTRAPFS += vsys-scripts
ALL += vsys-scripts

#
# plcapi
#
plcapi-MODULES := plcapi
plcapi-SPEC := PLCAPI.spec
ALL += plcapi
IN_MYPLC += plcapi

#
# drupal
# 
drupal-MODULES := drupal
drupal-SPEC := drupal.spec
drupal-BUILD-FROM-SRPM := yes
ALL += drupal
IN_MYPLC += drupal

#
# use the plewww module instead
#
plewww-MODULES := plewww
plewww-SPEC := plewww.spec
ALL += plewww
IN_MYPLC += plewww

#
# www-register-wizard
#
www-register-wizard-MODULES := www-register-wizard
www-register-wizard-SPEC := www-register-wizard.spec
ALL += www-register-wizard
IN_MYPLC += www-register-wizard

#
# pcucontrol
#
pcucontrol-MODULES := pcucontrol
pcucontrol-SPEC := pcucontrol.spec
ALL += pcucontrol

#
# monitor
#
#monitor-MODULES := monitor
#monitor-SPEC := Monitor.spec
#monitor-DEVEL-RPMS += net-snmp net-snmp-devel
#ALL += monitor
#IN_BOOTSTRAPFS += monitor

#
# PLC RT
#
plcrt-MODULES := PLCRT
plcrt-SPEC := plcrt.spec
ALL += plcrt

# f12 has 0.9-1 already
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 centos5)"
#
# pyopenssl
#
pyopenssl-MODULES := pyopenssl
pyopenssl-SPEC := pyOpenSSL.spec
pyopenssl-BUILD-FROM-SRPM := yes
ALL += pyopenssl
endif

#
# pyaspects
#
pyaspects-MODULES := pyaspects
pyaspects-SPEC := pyaspects.spec
pyaspects-BUILD-FROM-SRPM := yes
ALL += pyaspects

#
# ejabberd
#
ejabberd-MODULES := ejabberd
ejabberd-SPEC := ejabberd.spec
ejabberd-BUILD-FROM-SRPM := yes
ejabberd-DEVEL-RPMS += erlang pam-devel hevea
# not needed anymore on f12 and above, that come with 2.1.5, and we had 2.1.3
# so, this is relevant on f8 and centos5 only
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 centos5)"
ALL += ejabberd
endif

# sfa now uses the with statement that's not supported on python-2.4 - not even through __future__
build_sfa=true
ifeq "$(DISTRONAME)" "centos5"
build_sfa=false
endif

ifeq "$(build_sfa)" "true"
#
# sfa - Slice Facility Architecture
#
sfa-MODULES := sfa
sfa-SPEC := sfa.spec
ALL += sfa
endif

sface-MODULES := sface
sface-SPEC := sface.spec
ALL += sface

#
# nodeconfig
#
nodeconfig-MODULES := nodeconfig
nodeconfig-SPEC := nodeconfig.spec
ALL += nodeconfig
IN_MYPLC += nodeconfig

#
# bootmanager
#
bootmanager-MODULES := bootmanager
bootmanager-SPEC := bootmanager.spec
ALL += bootmanager
IN_MYPLC += bootmanager

#
# pypcilib : used in bootcd
# 
pypcilib-MODULES := pypcilib
pypcilib-SPEC := pypcilib.spec
ALL += pypcilib
IN_BOOTCD += pypcilib

#
# pyplnet
#
pyplnet-MODULES := pyplnet
pyplnet-SPEC := pyplnet.spec
ALL += pyplnet
IN_BOOTSTRAPFS += pyplnet
IN_MYPLC += pyplnet
IN_BOOTCD += pyplnet

#
# OMF resource controller
#
omf-resctl-MODULES := omf
omf-resctl-SPEC := omf-resctl.spec
ALL += omf-resctl
IN_SLIVER += omf-resctl

#
# OMF exp controller
#
omf-expctl-MODULES := omf
omf-expctl-SPEC := omf-expctl.spec
ALL += omf-expctl

#
# bootcd
#
bootcd-MODULES := bootcd build
bootcd-SPEC := bootcd.spec
bootcd-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcd-DEPEND-FILES := RPMS/yumgroups.xml
bootcd-RPMDATE := yes
ALL += bootcd
IN_MYPLC += bootcd

#
# LXC reference images
#
lxcref-MODULES := lxc-reference
lxcref-SPEC    := lxc-reference.spec
ALL += lxcref
IN_BOOTSTRAPFS += lxcref

#
# bootstrapfs
#
bootstrapfs-MODULES := bootstrapfs build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS)
bootstrapfs-DEPEND-FILES := RPMS/yumgroups.xml
bootstrapfs-RPMDATE := yes
ALL += bootstrapfs
IN_MYPLC += bootstrapfs

#
# noderepo
#
# all rpms resulting from packages marked as being in bootstrapfs and vserver
NODEREPO_RPMS = $(foreach package,$(IN_BOOTSTRAPFS) $(IN_NODEREPO) $(IN_SLIVER),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
NODEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(NODEREPO_RPMS))

noderepo-MODULES := bootstrapfs
noderepo-SPEC := noderepo.spec
# package requires all embedded packages
noderepo-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS) $(IN_NODEREPO) $(IN_SLIVER)
noderepo-DEPEND-FILES := RPMS/yumgroups.xml
#export rpm list to the specfile
noderepo-SPECVARS = node_rpms_plus=$(NODEREPO_RPMS_3PLUS)
noderepo-RPMDATE := yes
ALL += noderepo
IN_MYPLC += noderepo

#
# slicerepo
#
# all rpms resulting from packages marked as being in vserver
SLICEREPO_RPMS = $(foreach package,$(IN_SLIVER),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
SLICEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(SLICEREPO_RPMS))

slicerepo-MODULES := bootstrapfs
slicerepo-SPEC := slicerepo.spec
# package requires all embedded packages
slicerepo-DEPEND-PACKAGES := $(IN_SLIVER)
slicerepo-DEPEND-FILES := RPMS/yumgroups.xml
#export rpm list to the specfile
slicerepo-SPECVARS = slice_rpms_plus=$(SLICEREPO_RPMS_3PLUS)
slicerepo-RPMDATE := yes
ALL += slicerepo

#
# MyPLC : lightweight packaging, dependencies are yum-installed in a vserver
#
myplc-MODULES := myplc
myplc-SPEC := myplc.spec
myplc-DEPEND-FILES := myplc-release RPMS/yumgroups.xml
ALL += myplc

# myplc-docs only contains docs for PLCAPI and NMAPI, but
# we still need to pull MyPLC, as it is where the specfile lies, 
# together with the utility script docbook2drupal.sh
myplc-docs-MODULES := myplc plcapi nodemanager monitor
myplc-docs-SPEC := myplc-docs.spec
ALL += myplc-docs

# using some other name than myplc-release, as this is a make target already
release-MODULES := myplc
release-SPEC := myplc-release.spec
release-RPMDATE := yes
ALL += release
