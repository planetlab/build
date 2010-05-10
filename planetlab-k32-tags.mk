# $Id$
# $URL$

# build-SVNPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/branches/rhel6
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-4099-0
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.4.7-4
iptables-BUILD-FROM-SRPM := yes	# tmp
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.33-2
iproute-BUILD-FROM-SRPM := yes	# tmp
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/trunk
util-vserver-BUILD-FROM-SRPM := yes	# tmp
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
# Trellis is using a modified util-vserver-pl with the 2.6.27 kernel
# initial tag would be tags/util-vserver-pl-0.4-3
util-vserver-pl-SVNBRANCH	:= trellis
util-vserver-pl-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver-pl/branches/trellis
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-6
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNPATH		:= http://svn.planet-lab.org/svn/NodeManager/tags/NodeManager-2.0-6
# Trellis-specific NodeManager plugins
NodeManager-topo-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-topo/trunk
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-14
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-SVNBRANCH			:= 0.9
vsys-SVNPATH			:= http://svn.planet-lab.org/svn/vsys/tags/vsys-0.9-4
vsys-scripts-SVNPATH		:= http://svn.planet-lab.org/svn/vsys-scripts/tags/vsys-scripts-0.95-17
PLCAPI-SVNPATH			:= http://svn.planet-lab.org/svn/PLCAPI/tags/PLCAPI-5.0-8
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-13
PLEWWW-SVNPATH			:= http://svn.planet-lab.org/svn/PLEWWW/tags/PLEWWW-4.3-44
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-3
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/tags/pcucontrol-1.0-3
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-33
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-SVNPATH		:= http://svn.planet-lab.org/svn/pyaspects/tags/pyaspects-0.3-1
ejabberd-SVNPATH		:= http://svn.planet-lab.org/svn/ejabberd/tags/ejabberd-2.1.3-1
omf-SVNPATH			:= http://svn.planet-lab.org/svn/omf/tags/omf-5.3-2
###
sfa-SVNPATH			:= http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-10
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-5.0-2
BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/tags/BootManager-5.0-3
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-6
BootCD-SVNPATH			:= http://svn.planet-lab.org/svn/BootCD/tags/BootCD-5.0-2
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/tags/VserverReference-5.0-2
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-2.0-5
MyPLC-SVNPATH			:= http://svn.planet-lab.org/svn/MyPLC/tags/MyPLC-5.0-3
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1

# locating the right test directory - see make tests_svnpath
tests-SVNPATH			:= http://svn.planet-lab.org/svn/tests/tags/tests-5.0-5