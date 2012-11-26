# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

lxcsu-GITPATH			:= git://git.planet-lab.org/lxcsu.git@lxcsu-0.2-1
lxctools-BRANCH			:= openvswitch
lxctools-GITPATH		:= git://git.planet-lab.org/lxctools.git@openvswitch
transforward-GITPATH		:= git://git.onelab.eu/transforward.git@transforward-0.1-2
procprotect-GITPATH             := git://git.onelab.eu/procprotect.git@procprotect-0.1-3
ipfw-GITPATH                    := git://git.onelab.eu/ipfw.git@ipfw-20120610-2
nodeupdate-GITPATH		:= git://git.planet-lab.org/nodeupdate.git@nodeupdate-0.5-9
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
plnode-utils-GITPATH		:= git://git.onelab.eu/plnode-utils@plnode-utils-0.2-1
nodemanager-BRANCH		:= openvswitch
nodemanager-GITPATH             := git://git.onelab.eu/nodemanager.git@openvswitch
# Trellis-specific NodeManager plugins
nodemanager-topo-GITPATH	:= git://git.planet-lab.org/NodeManager-topo@master
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
#
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.planet-lab.org/codemux.git@codemux-0.1-15
fprobe-ulog-GITPATH             := git://git.planet-lab.org/fprobe-ulog.git@fprobe-ulog-1.1.4-2
libvirt-GITPATH                 := git://git.planet-lab.org/libvirt.git@libvirt-0.9.12-1
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
mom-GITPATH                     := git://git.planet-lab.org/mom.git@mom-2.3-5
inotify-tools-GITPATH		:= git://git.planet-lab.org/inotify-tools.git@inotify-tools-3.13-2
openvswitch-GITPATH		:= git://git.planet-lab.org/openvswitch.git@openvswitch-1.2-1
vsys-GITPATH			:= git://git.planet-lab.org/vsys.git@vsys-0.99-2
vsys-scripts-GITPATH		:= git://git.planet-lab.org/vsys-scripts@vsys-scripts-0.95-44
# somehow this won't mirror
bind_public-GITPATH             := git://git.onelab.eu/bind_public.git@bind_public-0.1-2
plcapi-GITPATH                  := git://git.onelab.eu/plcapi.git@plcapi-5.1-4
drupal-GITPATH                  := git://git.planet-lab.org/drupal.git@drupal-4.7-15
plewww-GITPATH                  := git://git.planet-lab.org/plewww.git@master
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
monitor-GITPATH			:= git://git.planet-lab.org/monitor@monitor-3.1-6
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-GITPATH               := git://git.planet-lab.org/pyopenssl.git@pyopenssl-0.9-2
###
pyaspects-GITPATH		:= git://git.planet-lab.org/pyaspects.git@pyaspects-0.4.1-2
omf-GITPATH                     := git://git.onelab.eu/omf.git@omf-5.3-11
###
sfa-GITPATH                     := git://git.planet-lab.org/sfa.git@sfa-2.1-17
sface-GITPATH                   := git://git.planet-lab.org/sface.git@sface-0.9-9
nodeconfig-GITPATH		:= git://git.planet-lab.org/nodeconfig.git@nodeconfig-5.0-7
bootmanager-BRANCH		:= lxc_devel
bootmanager-GITPATH             := git://git.planet-lab.org/bootmanager.git@bootmanager-5.1-3
pypcilib-GITPATH		:= git://git.planet-lab.org/pypcilib.git@pypcilib-0.2-10
pyplnet-BRANCH			:= openvswitch
pyplnet-GITPATH                 := git://git.planet-lab.org/pyplnet.git@openvswitch
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1
pcucontrol-GITPATH              := git://git.planet-lab.org/pcucontrol.git@pcucontrol-1.0-13
bootcd-GITPATH                  := git://git.planet-lab.org/bootcd.git@bootcd-5.1-2
sliceimage-BRANCH		:= openvswitch
sliceimage-GITPATH	        := git://git.onelab.eu/sliceimage.git@sliceimage-5.1-3
nodeimage-GITPATH               := git://git.planet-lab.org/nodeimage.git@nodeimage-2.1-3
myplc-GITPATH                   := git://git.planet-lab.org/myplc.git@myplc-5.1-4
# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.planet-lab.org/tests.git@tests-5.1-7
