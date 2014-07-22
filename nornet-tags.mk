# /=========================================================================\
# =             #     #                 #     #                             =
# =             ##    #   ####   #####  ##    #  ######   #####             =
# =             # #   #  #    #  #    # # #   #  #          #               =
# =             #  #  #  #    #  #    # #  #  #  #####      #               =
# =             #   # #  #    #  #####  #   # #  #          #               =
# =             #    ##  #    #  #   #  #    ##  #          #               =
# =             #     #   ####   #    # #     #  ######     #               =
# =                                                                         =
# =             A Real-World, Large-Scale Multi-Homing Testbed              =
# =                          https://www.nntb.no/                           =
# =                                                                         =
# = Contact: Thomas Dreibholz                                               =
# =          dreibh@simula.no, https://www.simula.no/people/dreibh          =
# \=========================================================================/

# ###### NorNet customisation ###############################################
linux-GITPATH                   := git://github.com/dreibh/planetlab-kernel.git@master
netperfmeter-GITPATH            := git://github.com/dreibh/netperfmeter.git@master
nornet-nn-GITPATH               := git://github.com/dreibh/nornet-nn.git@master
rsplib-GITPATH                  := git://github.com/dreibh/rsplib.git@master
subnetcalc-GITPATH              := git://github.com/dreibh/subnetcalc.git@master
# tracebox-GITPATH                := git://github.com/dreibh/tracebox.git@master
tsctp-GITPATH                   := git://github.com/dreibh/tsctp.git@master
# ###########################################################################

# ##### NorNet ########################
# -- transforward-GITPATH            := git://github.com/dreibh/planetlab-lxc-transforward.git@master
# -- procprotect-GITPATH             := git://github.com/dreibh/planetlab-lxc-procprotect.git@master
# -- ipfw-GITPATH                    := git://github.com/dreibh/planetlab-lxc-ipfw.git@master
plcapi-GITPATH                  := git://github.com/dreibh/planetlab-lxc-plcapi.git@master
bootcd-GITPATH                  := git://github.com/dreibh/planetlab-lxc-bootcd.git@master
nodemanager-GITPATH             := git://github.com/dreibh/planetlab-lxc-nodemanager.git@master
# #####################################

lxc-userspace-GITPATH           := git://git.onelab.eu/lxc-userspace.git@lxc-userspace-1.0-12
transforward-GITPATH            := git://git.onelab.eu/transforward.git@transforward-0.1-7
procprotect-GITPATH             := git://git.onelab.eu/procprotect.git@procprotect-0.4-5
# !!! ipfw still needs newer version! !!!
ipfw-GITPATH                    := git://git.code.sf.net/p/dummynet/code@155b6cd31089b4763297d579e9c9945393f00c40
comgt-GITPATH			:= git://git.onelab.eu/comgt.git@0.3
planetlab-umts-tools-GITPATH    := git://git.onelab.eu/planetlab-umts-tools.git@planetlab-umts-tools-0.7-1
nodeupdate-GITPATH              := git://git.onelab.eu/nodeupdate.git@nodeupdate-0.5-11
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
plnode-utils-GITPATH            := git://git.onelab.eu/plnode-utils.git@plnode-utils-0.2-2
# !!! Using NorNet customisation! !!! nodemanager-GITPATH             := git://git.planet-lab.org/nodemanager.git@master
#
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.onelab.eu/codemux.git@codemux-0.1-15
fprobe-ulog-GITPATH             := git://git.onelab.eu/fprobe-ulog.git@fprobe-ulog-1.1.4-3
libvirt-BRANCH	                := 1.2.5
libvirt-GITPATH                 := git://git.onelab.eu/libvirt.git@libvirt-1.2.5-1
libvirt-python-BRANCH           := 1.2.5
libvirt-python-GITPATH          := git://git.onelab.eu/libvirt-python.git@libvirt-python-1.2.5-1
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
mom-GITPATH                     := git://git.onelab.eu/mom.git@mom-2.3-5
inotify-tools-GITPATH		:= git://git.onelab.eu/inotify-tools.git@inotify-tools-3.13-2
openvswitch-GITPATH		:= git://git.onelab.eu/openvswitch.git@openvswitch-1.2-1
vsys-GITPATH			:= git://git.onelab.eu/vsys.git@vsys-0.99-3
vsys-scripts-GITPATH            := git://git.onelab.eu/vsys-scripts.git@vsys-scripts-0.95-49
bind_public-GITPATH             := git://git.onelab.eu/bind_public.git@bind_public-0.1-2
sliver-openvswitch-GITPATH      := git://git.onelab.eu/sliver-openvswitch.git@sliver-openvswitch-2.2.90-1
# !!! Using NorNet customisation! !!! plcapi-GITPATH                  := git://git.planet-lab.org/plcapi.git@plcapi-5.3-3
drupal-GITPATH                  := git://git.onelab.eu/drupal.git@drupal-4.7-15
plewww-GITPATH                  := git://git.onelab.eu/plewww.git@plewww-5.2-4
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
monitor-GITPATH			:= git://git.onelab.eu/monitor@monitor-3.1-6
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-GITPATH               := git://git.onelab.eu/pyopenssl.git@pyopenssl-0.9-2
pyaspects-GITPATH               := git://git.onelab.eu/pyaspects.git@pyaspects-0.4.1-3
nodeconfig-GITPATH              := git://git.onelab.eu/nodeconfig.git@nodeconfig-5.2-4
bootmanager-GITPATH             := git://git.onelab.eu/bootmanager.git@bootmanager-5.2-5
pypcilib-GITPATH                := git://git.onelab.eu/pypcilib.git@pypcilib-0.2-11
pyplnet-GITPATH                 := git://git.onelab.eu/pyplnet.git@pyplnet-4.3-18
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1
pcucontrol-GITPATH              := git://git.onelab.eu/pcucontrol.git@pcucontrol-1.0-13
###
# omf-resctl now comes from yum and gem, no need for rvm-ruby anymore
oml-GITPATH                     := git://git.onelab.eu/oml.git@oml-2.6.1-1
###
# !!! Using NorNet customisation! !!! bootcd-GITPATH                  := git://git.planet-lab.org/bootcd.git@bootcd-5.2-4
sliceimage-GITPATH              := git://git.onelab.eu/sliceimage.git@master
nodeimage-GITPATH               := git://git.onelab.eu/nodeimage.git@nodeimage-5.2-4
myplc-GITPATH                   := git://git.onelab.eu/myplc.git@myplc-5.3-2

#
sfa-BRANCH			:= geni-v3
sfa-GITPATH                     := git://git.onelab.eu/sfa.git@sfa-3.1-9
#
tests-GITPATH                   := git://git.onelab.eu/tests.git@tests-5.3-7
