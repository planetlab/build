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
# transforward: root context module for transparent port forwarding
#
transforward-MODULES := transforward
transforward-SPEC := transforward.spec
ALL += transforward
IN_NODEIMAGE += transforward

#
# procprotect: root context module for protecting against weaknesses in /proc
#
procprotect-MODULES := procprotect
procprotect-SPEC := procprotect.spec
ALL += procprotect
IN_NODEIMAGE += procprotect

#
# ipfw: root context module, and slice companion
#
ipfwroot-MODULES := ipfw
ipfwroot-SPEC := planetlab/ipfwroot.spec
ALL += ipfwroot
IN_NODEIMAGE += ipfwroot

ipfwslice-MODULES := ipfw
ipfwslice-SPEC := planetlab/ipfwslice.spec
ALL += ipfwslice

#
# madwifi
#
madwifi-MODULES := madwifi
madwifi-SPEC := madwifi.spec
madwifi-BUILD-FROM-SRPM := yes
ALL += madwifi
IN_NODEIMAGE += madwifi

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
# nodemanager
#
nodemanager-lib-MODULES := nodemanager
nodemanager-lib-SPEC := nodemanager-lib.spec
ALL += nodemanager-lib
IN_NODEIMAGE += nodemanager-lib

nodemanager-lxc-MODULES := nodemanager
nodemanager-lxc-SPEC := nodemanager-lxc.spec
ALL += nodemanager-lxc
IN_NODEIMAGE += nodemanager-lxc

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
IN_NODEIMAGE += libvirt

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
#IN_NODEIMAGE += mom

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
# openvswitch-MODULES := openvswitch
# openvswitch-SPEC := openvswitch.spec
# openvswitch-DEPEND-DEVEL-RPMS += kernel-devel
# IN_NODEIMAGE += openvswitch
# # build only on f14 as f16 has this natively
# ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f14)"
# ALL += openvswitch
# endif

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
vsys-scripts-SPEC := vsys-scripts.spec
IN_NODEIMAGE += vsys-scripts
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
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 f12 centos5)"
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
# lxc-specific sliceimage initialization
# 
lxc-sliceimage-MODULES	:= sliceimage
lxc-sliceimage-SPEC	:= lxc-sliceimage.spec
lxc-sliceimage-RPMDATE	:= yes
ALL			+= lxc-sliceimage
IN_NODEIMAGE		+= lxc-sliceimage

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
