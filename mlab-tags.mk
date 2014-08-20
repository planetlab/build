mkinitrd-GITPATH		:= git://git.planet-lab.org/mkinitrd.git@mkinitrd-5.1.19.6-2
linux-2.6-BRANCH		:= 32 # This line is not so defunct
linux-2.6-GITPATH		:= git://git.planet-lab.org/linux-2.6.git@rhel6-mlab
# help out spec2make on f8 and centos5, due to a bug in rpm
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 centos5)"
kernel-WHITELIST-RPMS	:= kernel-devel,kernel-headers
endif
kernel-STOCK-DEVEL-RPMS		+= elfutils-libelf-devel
madwifi-GITPATH                 := git://git.planet-lab.org/madwifi.git@madwifi-4132-6
# iptables 1.4.7 creates libxtables.so.4 while later versions libxtables.so.5
# this breaks dependencies for other centos6 packages.
iptables-GITPATH                := git://git.planet-lab.org/iptables.git@iptables-1.4.7-5
# we use the stock iproute2 with 2.6.32, since our gre patch is not needed anymore with that kernel
# note that this should be consistently reflected in yumexclude
ALL := $(filter-out iproute,$(ALL))
util-vserver-GITPATH            := git://git.planet-lab.org/util-vserver.git@util-vserver-0.30.216-21
libnl-GITPATH			:= git://git.planet-lab.org/libnl.git@libnl-1.1-2
util-vserver-pl-GITPATH		:= git://git.planet-lab.org/util-vserver-pl.git@util-vserver-pl-0.4-29
nodeupdate-GITPATH		:= git://git.planet-lab.org/nodeupdate.git@nodeupdate-0.5-11
plnode-utils-GITPATH        	:= git://git.planet-lab.org/plnode-utils.git@plnode-utils-0.2-2
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
nodemanager-GITPATH             := git://git.planet-lab.org/nodemanager.git@master
# Trellis-specific NodeManager plugins
nodemanager-topo-GITPATH	:= git://git.planet-lab.org/NodeManager-topo@master
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
#
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.planet-lab.org/codemux.git@codemux-0.1-15
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-3
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
mom-GITPATH			:= git://git.planet-lab.eu/mom.git@mom-2.3-4
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
openvswitch-GITPATH		:= git://git.planet-lab.org/openvswitch.git@master
vsys-GITPATH			:= git://git.planet-lab.org/vsys.git@vsys-0.99-3
vsys-scripts-GITPATH		:= git://git.planet-lab.org/vsys-scripts@vsys-scripts-0.95-49
plcapi-GITPATH                  := git://git.planet-lab.org/plcapi.git@plcapi-5.3-5
drupal-GITPATH                  := git://git.planet-lab.org/drupal.git@drupal-4.7-15
plewww-GITPATH                  := git://git.planet-lab.org/plewww.git@plewww-5.2-4
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
monitor-GITPATH			:= git://git.planet-lab.org/monitor@monitor-3.1-6
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-GITPATH               := git://git.planet-lab.org/pyopenssl.git@pyopenssl-0.9-2
###
pyaspects-GITPATH		:= git://git.planet-lab.org/pyaspects.git@pyaspects-0.4.1-3
omf-GITPATH                     := git://git.onelab.eu/omf.git@omf-5.3-11
###
sfa-GITPATH                     := git://git.planet-lab.org/sfa.git@sfa-3.1-10
sface-GITPATH                   := git://git.planet-lab.org/sface.git@sface-0.9-9
nodeconfig-GITPATH              := git://git.planet-lab.org/nodeconfig.git@nodeconfig-5.2-4
bootmanager-GITPATH             := git://git.planet-lab.org/bootmanager.git@bootmanager-5.2-5
pypcilib-GITPATH		:= git://git.planet-lab.org/pypcilib.git@pypcilib-0.2-11
pyplnet-GITPATH                 := git://git.planet-lab.org/pyplnet.git@pyplnet-4.3-18
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1
pcucontrol-GITPATH              := git://git.planet-lab.org/pcucontrol.git@pcucontrol-1.0-13
bootcd-GITPATH                  := git://git.planet-lab.org/bootcd.git@bootcd-5.2-4
sliceimage-GITPATH              := git://git.planet-lab.org/sliceimage.git@sliceimage-5.1-8
nodeimage-GITPATH               := git://git.planet-lab.org/nodeimage.git@nodeimage-5.2-3
myplc-GITPATH                   := git://git.planet-lab.org/myplc.git@myplc-5.3-2
# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.planet-lab.org/tests.git@tests-5.3-8
