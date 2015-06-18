###
linux-2.6-BRANCH		:= 32
linux-2.6-GITPATH               := git://git.onelab.eu/linux-2.6.git@linux-2.6-32-36
# ipfw-sourceforge.git (obsolete) mirrored on git.onelab.eu from git://git.code.sf.net/p/dummynet/code
# ipfw-GITPATH			:= git://git.onelab.eu/ipfw-sourceforge.git@ipfw-20130423-1
# ipfw-google.git (current) is mirrored on git.onelab.eu from https://code.google.com/p/dummynet
ipfw-GITPATH                    := git://git.onelab.eu/ipfw-google.git@e717cdd4bef764a4aa7babedc54220b35b04c777

madwifi-GITPATH                 := git://git.onelab.eu/madwifi.git@madwifi-4132-6
iptables-GITPATH                := git://git.onelab.eu/iptables.git@iptables-1.4.10-5
###
comgt-GITPATH			:= git://git.onelab.eu/comgt.git@0.3
planetlab-umts-tools-GITPATH    := git://git.onelab.eu/planetlab-umts-tools.git@planetlab-umts-tools-0.6-6
util-vserver-GITPATH            := git://git.onelab.eu/util-vserver.git@util-vserver-0.30.216-21
libnl-GITPATH			:= git://git.onelab.eu/libnl.git@libnl-1.1-2
util-vserver-pl-GITPATH         := git://git.onelab.eu/util-vserver-pl.git@util-vserver-pl-0.4-29
nodeupdate-GITPATH              := git://git.onelab.eu/nodeupdate.git@nodeupdate-0.5-11
PingOfDeath-GITPATH		:= git://git.onelab.eu/pingofdeath.git@PingOfDeath-2.2-1
plnode-utils-GITPATH            := git://git.onelab.eu/plnode-utils.git@plnode-utils-0.2-2
nodemanager-GITPATH             := git://git.onelab.eu/nodemanager.git@nodemanager-5.2-16
pl_sshd-GITPATH			:= git://git.onelab.eu/pl_sshd.git@pl_sshd-1.0-11
codemux-GITPATH			:= git://git.onelab.eu/codemux.git@codemux-0.1-15
fprobe-ulog-GITPATH             := git://git.onelab.eu/fprobe-ulog.git@fprobe-ulog-1.1.4-3
pf2slice-GITPATH		:= git://git.onelab.eu/pf2slice.git@pf2slice-1.0-2
mom-GITPATH                     := git://git.onelab.eu/mom.git@mom-2.3-5
inotify-tools-GITPATH		:= git://git.planet-lab.org/inotify-tools.git@inotify-tools-3.13-2
vsys-GITPATH                    := git://git.onelab.eu/vsys.git@vsys-0.99-3
vsys-scripts-GITPATH            := git://git.onelab.eu/vsys-scripts.git@vsys-scripts-0.95-50
autoconf-GITPATH		:= git://git.onelab.eu/autoconf@autoconf-2.69-1
bind_public-GITPATH             := git://git.onelab.eu/bind_public.git@bind_public-0.1-2
sliver-openvswitch-GITPATH      := git://git.onelab.eu/sliver-openvswitch.git@sliver-openvswitch-2.2.90-1
plcapi-GITPATH                  := git://git.onelab.eu/plcapi.git@master
drupal-GITPATH                  := git://git.onelab.eu/drupal.git@drupal-4.7-15
plewww-GITPATH                  := git://git.onelab.eu/plewww.git@plewww-5.2-5
www-register-wizard-GITPATH	:= git://git.onelab.eu/www-register-wizard.git@www-register-wizard-4.3-5
pcucontrol-GITPATH              := git://git.onelab.eu/pcucontrol.git@pcucontrol-1.0-13
monitor-GITPATH                 := git://git.onelab.eu/monitor.git@monitor-3.1-6
PLCRT-GITPATH			:= git://git.onelab.eu/plcrt.git@PLCRT-1.0-11
pyopenssl-GITPATH               := git://git.onelab.eu/pyopenssl.git@pyopenssl-0.9-2
pyaspects-GITPATH               := git://git.onelab.eu/pyaspects.git@pyaspects-0.4.1-3
nodeconfig-GITPATH              := git://git.onelab.eu/nodeconfig.git@nodeconfig-5.2-4
bootmanager-GITPATH             := git://git.onelab.eu/bootmanager.git@master
pypcilib-GITPATH                := git://git.onelab.eu/pypcilib.git@pypcilib-0.2-11
pyplnet-GITPATH                 := git://git.onelab.eu/pyplnet.git@pyplnet-4.3-18
###
rvm-ruby-BRANCH			:= planetlab
rvm-ruby-GITPATH                := git://git.onelab.eu/rvm-ruby.git@rvm-ruby-1.22.9-1
oml-GITPATH                     := git://git.onelab.eu/oml.git@oml-2.6.1-1
###
bootcd-GITPATH                  := git://git.onelab.eu/bootcd.git@master
sliceimage-GITPATH              := git://git.onelab.eu/sliceimage.git@sliceimage-5.1-10
nodeimage-GITPATH               := git://git.onelab.eu/nodeimage.git@master
myplc-GITPATH                   := git://git.onelab.eu/myplc.git@myplc-5.3-3
DistributedRateLimiting-GITPATH	:= git://git.onelab.eu/distributedratelimiting.git@DistributedRateLimiting-0.1-1

#
sfa-GITPATH                     := git://git.onelab.eu/sfa.git@sfa-3.1-18
#
# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.onelab.eu/tests.git@master
