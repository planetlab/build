#
# declare the packages to be built and their dependencies
# initial version from Mark Huang
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
# rewritten by Thierry Parmentelat - INRIA Sophia Antipolis
#
# see doc in Makefile  
#

# mkinitrd
#
ifeq "$(PLDISTROTAGS)" "planetlab-k32-tags.mk"
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),centos5 centos6)"
mkinitrd-MODULES := mkinitrd
mkinitrd-SPEC := mkinitrd.spec
mkinitrd-BUILD-FROM-SRPM := yes
mkinitrd-DEVEL-RPMS += parted-devel glib2-devel libdhcp4client-devel libdhcp6client-devel libdhcp-devel 
mkinitrd-DEVEL-RPMS += device-mapper libselinux-devel libsepol-devel libnl-devel
ALL += mkinitrd
IN_BOOTCD += mkinitrd
IN_SLICEIMAGE += mkinitrd 
IN_NODEIMAGE += mkinitrd
IN_MYPLC += mkinitrd
endif
endif
#
# kernel
#
# use a package name with srpm in it:
# so the source rpm is created by running make srpm in the codebase
#

kernel-MODULES := linux-2.6
kernel-SPEC := kernel-2.6.spec
kernel-BUILD-FROM-SRPM := yes
ifeq "$(HOSTARCH)" "i386"
kernel-RPMFLAGS:= --target i686
else
kernel-RPMFLAGS:= --target $(HOSTARCH)
endif
kernel-SPECVARS += kernelconfig=planetlab
KERNELS += kernel

kernels: $(KERNELS)
kernels-clean: $(foreach package,$(KERNELS),$(package)-clean)

ALL += $(KERNELS)
# this is to mark on which image a given rpm is supposed to go
IN_BOOTCD += $(KERNELS)
IN_SLICEIMAGE += $(KERNELS)
IN_NODEIMAGE += $(KERNELS)

#
# madwifi
#
# skip this with k32/f8
ifneq "" "$(findstring k32,$(PLDISTROTAGS))"
ifneq "$(DISTRONAME)" "f8"
madwifi-MODULES := madwifi
madwifi-SPEC := madwifi.spec
madwifi-BUILD-FROM-SRPM := yes
madwifi-DEPEND-DEVEL-RPMS += kernel-devel
madwifi-SPECVARS = kernel_version=$(kernel.rpm-version) \
	kernel_release=$(kernel.rpm-release) \
	kernel_arch=$(kernel.rpm-arch)
ALL += madwifi
IN_NODEIMAGE += madwifi
endif
endif

#
# iptables
#
iptables-MODULES := iptables
iptables-SPEC := iptables.spec
iptables-BUILD-FROM-SRPM := yes	
iptables-DEPEND-DEVEL-RPMS += kernel-devel kernel-headers
ALL += iptables
IN_NODEIMAGE += iptables

#
# iproute
#
iproute-MODULES := iproute2
iproute-SPEC := iproute.spec
iproute-BUILD-FROM-SRPM := yes	
#ALL += iproute
#IN_NODEIMAGE += iproute
#IN_SLICEIMAGE += iproute
#IN_BOOTCD += iproute

#
# util-vserver
#
util-vserver-MODULES := util-vserver
util-vserver-SPEC := util-vserver.spec
# starting with 0.4
util-vserver-BUILD-FROM-SRPM := yes
util-vserver-RPMFLAGS:= --without dietlibc --without doc
ALL += util-vserver
IN_NODEIMAGE += util-vserver

#
# libnl - local import
# we need either 1.1 or at least 1.0.pre6
# rebuild this on centos5 - see yumexclude
#
local_libnl=false
ifeq "$(DISTRONAME)" "centos5"
local_libnl=true
endif

ifeq "$(local_libnl)" "true"
libnl-MODULES := libnl
libnl-SPEC := libnl.spec
libnl-BUILD-FROM-SRPM := yes
# this sounds like the thing to do, but in fact linux/if_vlan.h comes with kernel-headers
libnl-DEPEND-DEVEL-RPMS += kernel-devel kernel-headers
ALL += libnl
IN_NODEIMAGE += libnl
endif

#
# util-vserver-pl
#
util-vserver-pl-MODULES := util-vserver-pl
util-vserver-pl-SPEC := util-vserver-pl.spec
util-vserver-pl-DEPEND-DEVEL-RPMS += util-vserver-lib util-vserver-devel util-vserver-core 
ifeq "$(local_libnl)" "true"
util-vserver-pl-DEPEND-DEVEL-RPMS += libnl libnl-devel
endif
ALL += util-vserver-pl
IN_NODEIMAGE += util-vserver-pl

#
# NodeUpdate
#
nodeupdate-MODULES := nodeupdate
nodeupdate-SPEC := NodeUpdate.spec
ALL += nodeupdate
IN_NODEIMAGE += nodeupdate

#
# ipod
#
ipod-MODULES := PingOfDeath
ipod-SPEC := ipod.spec
ALL += ipod
IN_NODEIMAGE += ipod

#
# NodeManager
#
#nodemanager-MODULES := nodemanager
#nodemanager-SPEC := NodeManager.spec
#ALL += nodemanager
#IN_NODEIMAGE += nodemanager

# nodemanager
nodemanager-lib-MODULES := nodemanager
nodemanager-lib-SPEC := nodemanager-lib.spec
ALL += nodemanager-lib
IN_NODEIMAGE += nodemanager-lib
nodemanager-vs-MODULES := nodemanager
nodemanager-vs-SPEC := nodemanager-vs.spec
ALL += nodemanager-vs
IN_NODEIMAGE += nodemanager-vs


#
# plnode-utils
# 
plnode-utils-MODULES := plnode-utils
plnode-utils-SPEC := plnode-utils-vs.spec
ALL += plnode-utils
IN_NODEIMAGE += plnode-utils

#
# pl_sshd
#
sshd-MODULES := pl_sshd
sshd-SPEC := pl_sshd.spec
ALL += sshd
IN_NODEIMAGE += sshd

#
# codemux: Port 80 demux
#
codemux-MODULES := codemux
codemux-SPEC   := codemux.spec
ALL += codemux
IN_NODEIMAGE += codemux

#
# fprobe-ulog
#
fprobe-ulog-MODULES := fprobe-ulog
fprobe-ulog-SPEC := fprobe-ulog.spec
ALL += fprobe-ulog
IN_NODEIMAGE += fprobe-ulog

#
# DistributedRateLimiting
#
DistributedRateLimiting-MODULES := DistributedRateLimiting
DistributedRateLimiting-SPEC := DistributedRateLimiting.spec
ALL += DistributedRateLimiting
IN_NODEREPO += DistributedRateLimiting

#
# pf2slice
#
pf2slice-MODULES := pf2slice
pf2slice-SPEC := pf2slice.spec
ALL += pf2slice

#
# PlanetLab Mom: Cleans up your mess
#
mom-MODULES := mom
mom-SPEC := pl_mom.spec
ALL += mom
IN_NODEIMAGE += mom

#
# inotify-tools - local import
# rebuild this on centos5 (not found) - see yumexclude
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
IN_NODEIMAGE += inotify-tools
ALL += inotify-tools
endif

#
# openvswitch
#
openvswitch-MODULES := openvswitch
openvswitch-SPEC := openvswitch.spec
openvswitch-DEPEND-DEVEL-RPMS += kernel-devel

#ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f14 f15 f16)"
#IN_NODEIMAGE += openvswitch
#ALL += openvswitch
#endif

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
IN_NODEIMAGE += vsys
ALL += vsys

#
# vsyssh : installed in slivers
#
vsyssh-MODULES := vsys
vsyssh-SPEC := vsyssh.spec
IN_SLICEIMAGE += vsyssh
ALL += vsyssh

#
# vsys-scripts
#
vsys-scripts-MODULES := vsys-scripts
vsys-scripts-SPEC := root-context/vsys-scripts.spec
IN_NODEIMAGE += vsys-scripts
ALL += vsys-scripts

#
# plcapi
#
plcapi-MODULES := plcapi
plcapi-SPEC := plcapi.spec
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
monitor-MODULES := monitor
monitor-SPEC := Monitor.spec
monitor-DEVEL-RPMS += net-snmp net-snmp-devel
ALL += monitor
#IN_NODEIMAGE += monitor

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

# sfa now uses the with statement that's not supported on python-2.4 - not even through __future__
# In addition we now use sqlalchemy and 0.5 as per f12 is not compatible with our model
build_sfa=true
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 f12 centos5 centos6)"
build_sfa=false
endif

ifeq "$(build_sfa)" "true"
#
# sfa - Slice Facility Architecture
#
sfa-MODULES := sfa
sfa-SPEC := sfa.spec
ALL += sfa

sface-MODULES := sface
sface-SPEC := sface.spec
ALL += sface
endif

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
IN_NODEIMAGE += pyplnet
IN_MYPLC += pyplnet
IN_BOOTCD += pyplnet

build_omf=false
ifeq "$(build_omf)" "true"
#
# OMF resource controller
#
omf-resctl-MODULES := omf
omf-resctl-SPEC := omf-resctl.spec
ALL += omf-resctl
IN_SLICEIMAGE += omf-resctl

#
# OMF exp controller
#
omf-expctl-MODULES := omf
omf-expctl-SPEC := omf-expctl.spec
ALL += omf-expctl
endif


#
# bootcdR630 -- This is the bootcd for R630
#
bootcdR630-MODULES := bootcd build
bootcdR630-SPEC := bootcd.spec
bootcdR630-BUILDSPEC := bootcdR630.spec
bootcdR630-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcdR630-DEPEND-FILES := RPMS/yumgroups.xml
bootcdR630-RPMDATE := yes
bootcdR630-SPECVARS = _arch=$(HOSTARCH)-r630
ALL += bootcdR630
IN_MYPLC += bootcdR630


#
# bootcdR420
#
bootcdR420-MODULES := bootcd build
bootcdR420-SPEC := bootcd.spec
bootcdR420-BUILDSPEC := bootcdR420.spec
bootcdR420-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcdR420-DEPEND-FILES := RPMS/yumgroups.xml
bootcdR420-RPMDATE := yes
bootcdR420-SPECVARS = _arch=$(HOSTARCH)-r420
ALL += bootcdR420
IN_MYPLC += bootcdR420


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
# images for slices
#
sliceimage-MODULES := sliceimage build
sliceimage-SPEC := sliceimage.spec
sliceimage-DEPEND-PACKAGES := $(IN_SLICEIMAGE)
sliceimage-DEPEND-FILES := RPMS/yumgroups.xml
sliceimage-RPMDATE := yes
ALL += sliceimage
IN_NODEIMAGE += sliceimage

#
# vserver-specific sliceimage initialization
# 
vserver-sliceimage-MODULES := sliceimage
vserver-sliceimage-SPEC    := vserver-sliceimage.spec
vserver-sliceimage-RPMDATE := yes
ALL			   += vserver-sliceimage
IN_NODEIMAGE		   += vserver-sliceimage

#
# nodeimage
#
nodeimage-MODULES := nodeimage build
nodeimage-SPEC := nodeimage.spec
nodeimage-DEPEND-PACKAGES := $(IN_NODEIMAGE)
nodeimage-DEPEND-FILES := RPMS/yumgroups.xml
nodeimage-RPMDATE := yes
ALL += nodeimage
IN_MYPLC += nodeimage

#
# noderepo
#
# all rpms resulting from packages marked as being in nodeimage and sliceimage
NODEREPO_RPMS = $(foreach package,$(IN_NODEIMAGE) $(IN_NODEREPO) $(IN_SLICEIMAGE),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
NODEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(NODEREPO_RPMS))

noderepo-MODULES := nodeimage
noderepo-SPEC := noderepo.spec
# package requires all embedded packages
noderepo-DEPEND-PACKAGES := $(IN_NODEIMAGE) $(IN_NODEREPO) $(IN_SLICEIMAGE)
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
SLICEREPO_RPMS = $(foreach package,$(IN_SLICEIMAGE),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
SLICEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(SLICEREPO_RPMS))

slicerepo-MODULES := nodeimage
slicerepo-SPEC := slicerepo.spec
# package requires all embedded packages
slicerepo-DEPEND-PACKAGES := $(IN_SLICEIMAGE)
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
