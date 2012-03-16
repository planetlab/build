# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

# lxcbuild is a tag
linux-3-GITPATH 		:= git://git.planet-lab.org/linux-3.git@lxcbuild
kernel-DEVEL-RPMS		+= elfutils-libelf-devel
nodeupdate-GITPATH		:= git://git.planet-lab.org/nodeupdate.git@nodeupdate-0.5-9
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
nodemanager-GITPATH             := git://git.planet-lab.org/nodemanager.git@lxc_devel
# Trellis-specific NodeManager plugins
nodemanager-topo-GITPATH	:= git://git.planet-lab.org/NodeManager-topo@master
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
#
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.planet-lab.org/codemux.git@codemux-0.1-15
fprobe-ulog-GITPATH             := git://git.planet-lab.org/fprobe-ulog.git@fprobe-ulog-1.1.4-1
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-GITPATH                     := git://git.planet-lab.org/mom.git@Mom-2.3-4
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
openvswitch-GITPATH		:= git://git.planet-lab.org/openvswitch.git@master
vsys-GITPATH			:= git://git.planet-lab.org/vsys.git@vsys-0.99-2
vsys-scripts-GITPATH		:= git://git.planet-lab.org/vsys-scripts@vsys-scripts-0.95-35
plcapi-GITPATH                  := git://git.onelab.eu/plcapi.git@master
drupal-GITPATH                  := git://git.planet-lab.org/drupal.git@drupal-4.7-15
plewww-GITPATH			:= git://git.planet-lab.org/plewww@plewww-4.3-70
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
monitor-GITPATH			:= git://git.planet-lab.org/monitor@monitor-3.1-6
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-GITPATH               := git://git.planet-lab.org/pyopenssl.git@pyopenssl-0.9-2
###
pyaspects-GITPATH		:= git://git.planet-lab.org/pyaspects.git@pyaspects-0.4.1-2
ejabberd-GITPATH		:= git://git.planet-lab.org/ejabberd.git@ejabberd-2.1.6-2
omf-GITPATH                     := git://git.onelab.eu/omf.git@omf-5.3-11
###
sfa-GITPATH                     := git://git.planet-lab.org/sfa.git@sfa-2.0-7
sface-GITPATH                   := git://git.planet-lab.org/sface.git@sface-0.9-5
nodeconfig-GITPATH		:= git://git.planet-lab.org/nodeconfig.git@nodeconfig-5.0-6
bootmanager-GITPATH             := git://git.planet-lab.org/bootmanager.git@lxcbuild
pypcilib-GITPATH		:= git://git.planet-lab.org/pypcilib.git@pypcilib-0.2-10
pyplnet-GITPATH                 := git://git.planet-lab.org/pyplnet.git@pyplnet-4.3-11
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1
pcucontrol-GITPATH              := git://git.planet-lab.org/pcucontrol.git@pcucontrol-1.0-12
bootcd-GITPATH                  := git://git.planet-lab.org/bootcd.git@bootcd-5.0-11
bootstrapfs-GITPATH             := git://git.planet-lab.org/bootstrapfs.git@bootstrapfs-2.0-14
myplc-GITPATH                   := git://git.planet-lab.org/myplc.git@myplc-5.0-19
# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.planet-lab.org/tests.git@tests-5.0-37
libvirt-GITPATH                 := git://git.planet-lab.org/libvirt.git@lxcbuild
lxc-reference-GITPATH           := git://git.planet-lab.org/lxc-reference.git@master
