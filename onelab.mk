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
#
kernel-STOCK-DEVEL-RPMS	+= elfutils-libelf-devel
# help out spec2make on f8 and centos5, due to a bug in rpm 
# ditto on f16 for spec2make.py - tmp hopefully
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 f16 centos5)"
kernel-WHITELIST-RPMS := kernel-devel,kernel-headers
endif

kernels: $(KERNELS)
kernels-clean: $(foreach package,$(KERNELS),$(package)-clean)

ALL += $(KERNELS)
# this is to mark on which image a given rpm is supposed to go
IN_BOOTCD += $(KERNELS)
#IN_SLICEIMAGE += $(KERNELS)
IN_NODEIMAGE += $(KERNELS)

#
# ipfw: root context module, and slice companion
#
ipfwroot-MODULES := ipfw
ipfwroot-SPEC := planetlab/ipfwroot.spec
ipfwroot-LOCAL-DEVEL-RPMS += kernel-devel
ipfwroot-SPECVARS = kernel_version=$(kernel.rpm-version) \
        kernel_release=$(kernel.rpm-release) \
        kernel_arch=$(kernel.rpm-arch)
ALL += ipfwroot
IN_NODEIMAGE += ipfwroot

ipfwslice-MODULES := ipfw
ipfwslice-SPEC := planetlab/ipfwslice.spec
ALL += ipfwslice

#
# madwifi
#
# skip this with k32/f8
ifneq "" "$(findstring k32,$(PLDISTROTAGS))"
ifneq "$(DISTRONAME)" "f8"
madwifi-MODULES := madwifi
madwifi-SPEC := madwifi.spec
madwifi-BUILD-FROM-SRPM := yes
madwifi-LOCAL-DEVEL-RPMS += kernel-devel
madwifi-SPECVARS = kernel_version=$(kernel.rpm-version) \
	kernel_release=$(kernel.rpm-release) \
	kernel_arch=$(kernel.rpm-arch)
ALL += madwifi
IN_NODEIMAGE += madwifi
endif
endif

#
# comgt
# 
comgt-MODULES := comgt
comgt-SPEC := comgt.spec
IN_NODEIMAGE += comgt
ALL += comgt

#
# umts: root context stuff
#
umts-backend-MODULES := planetlab-umts-tools
umts-backend-SPEC := backend.spec
IN_NODEIMAGE += umts-backend
ALL += umts-backend

#
# umts: slice tools
#
umts-frontend-MODULES := planetlab-umts-tools
umts-frontend-SPEC := frontend.spec
IN_SLICEIMAGE += umts-frontend
ALL += umts-frontend

#
# iptables
#
iptables-MODULES := iptables
iptables-SPEC := iptables.spec
iptables-BUILD-FROM-SRPM := yes	
iptables-LOCAL-DEVEL-RPMS += kernel-devel kernel-headers
ALL += iptables
IN_NODEIMAGE += iptables

###
# we use the stock iproute2 with 2.6.32, since our gre patch is not needed anymore with that kernel
# note that this should be consistently reflected in nodeyumexclude
# #
# # iproute
# #
# iproute-MODULES := iproute2
# iproute-SPEC := iproute.spec
# iproute-BUILD-FROM-SRPM := yes	
# ALL += iproute
# IN_NODEIMAGE += iproute
# IN_SLICEIMAGE += iproute
# IN_BOOTCD += iproute

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
libnl-LOCAL-DEVEL-RPMS += kernel-devel kernel-headers
ALL += libnl
IN_NODEIMAGE += libnl
endif

#
# util-vserver-pl
#
util-vserver-pl-MODULES := util-vserver-pl
util-vserver-pl-SPEC := util-vserver-pl.spec
util-vserver-pl-LOCAL-DEVEL-RPMS += util-vserver-lib util-vserver-devel util-vserver-core 
ifeq "$(local_libnl)" "true"
util-vserver-pl-LOCAL-DEVEL-RPMS += libnl libnl-devel
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
# plnode-utils
# 
plnode-utils-MODULES := plnode-utils
plnode-utils-SPEC := plnode-utils-vs.spec
ALL += plnode-utils
IN_NODEIMAGE += plnode-utils

#
# nodemanager
#
nodemanager-lib-MODULES := nodemanager
nodemanager-lib-SPEC := nodemanager-lib.spec
ALL += nodemanager-lib
IN_NODEIMAGE += nodemanager-lib

nodemanager-vs-MODULES := nodemanager
nodemanager-vs-SPEC := nodemanager-vs.spec
ALL += nodemanager-vs
IN_NODEIMAGE += nodemanager-vs

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
# on f16 somehow configure screws up and defines LDFLAGS=-Wl,-z,relro which ld does not like..
ifneq "$(DISTRONAME)" "f16"
DistributedRateLimiting-MODULES := DistributedRateLimiting
DistributedRateLimiting-SPEC := DistributedRateLimiting.spec
ALL += DistributedRateLimiting
IN_NODEREPO += DistributedRateLimiting
endif

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

# #
# # openvswitch
# #
# openvswitch-MODULES := openvswitch
# openvswitch-SPEC := openvswitch.spec
# openvswitch-LOCAL-DEVEL-RPMS += kernel-devel
# 
# ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f14 f15 f16)"
# IN_NODEIMAGE += openvswitch
# ALL += openvswitch
# endif

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
# ocaml-docs is not needed anymore but keep it on a tmp basis as some tags may still have it
vsys-STOCK-DEVEL-RPMS += ocaml-ocamldoc ocaml-docs
ifeq "$(local_inotify_tools)" "true"
vsys-LOCAL-DEVEL-RPMS += inotify-tools inotify-tools-devel
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

vsys-wrapper-MODULES := vsys-scripts
vsys-wrapper-SPEC := slice-context/vsys-wrapper.spec
IN_SLICEIMAGE += vsys-wrapper
ALL += vsys-wrapper

# openvswitch requires an autoconf more recent than what f12 has
ifeq "$(DISTRONAME)" "f12"
autoconf-MODULES := autoconf
autoconf-SPEC := autoconf.spec
autoconf-BUILD-FROM-SRPM := yes
ALL += autoconf
endif

#
# bind_public
#
bind_public-MODULES := bind_public
bind_public-SPEC := bind_public.spec
IN_SLICEIMAGE += bind_public
ALL += bind_public

#
# sliver-openvswitch
#
sliver-openvswitch-MODULES := sliver-openvswitch
sliver-openvswitch-SPEC := sliver-openvswitch.spec
ifeq "$(DISTRONAME)" "f12"
sliver-openvswitch-LOCAL-DEVEL-RPMS-CRUCIAL := autoconf
endif
IN_SLICEIMAGE += sliver-openvswitch
ALL += sliver-openvswitch

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
monitor-STOCK-DEVEL-RPMS += net-snmp net-snmp-devel
ALL += monitor
IN_NODEIMAGE += monitor

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

#
# for OMF resource controller as  a gem : rvm-ruby has right version of ruby and related gem stuff
#
rvm-ruby-MODULES := rvm-ruby
rvm-ruby-SPEC := rpm/rvm-ruby.spec
rvm-ruby-STOCK-DEVEL-RPMS := chrpath libyaml-devel libffi-devel libxslt-devel
ALL += rvm-ruby

#
# OML measurement library
#
oml-MODULES := oml
oml-STOCK-DEVEL-RPMS += sqlite-devel 
oml-SPEC := liboml.spec
ALL += oml

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

##############################
#
# sfa - Slice Facility Architecture
#
sfa-MODULES := sfa
sfa-SPEC := sfa.spec
ALL += sfa

