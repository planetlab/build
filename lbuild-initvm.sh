#!/bin/bash
# -*-shell-*-

#shopt -s huponexit

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)
BUILD_DIR=$(pwd)

# pkgs parsing utilities
PATH=$(dirname $0):$PATH export PATH
. build.common

DEFAULT_FCDISTRO=f20
DEFAULT_PLDISTRO=lxc
DEFAULT_PERSONALITY=linux64

COMMAND_LBUILD="lbuild-initvm.sh"
COMMAND_LTEST="ltest-initvm.sh"

##########
# when creating build boxes we use private NAT'ed addresses for the VMs
# as per virbr0 that is taken care of by libvirt at startup
PRIVATE_BRIDGE="virbr0"
PRIVATE_PREFIX="192.168.122."
PRIVATE_GATEWAY="192.168.122.1"
# beware that changing this would break the logic of random_private_byte...
PRIVATE_MASKLEN=24

# we just try randomly in that range until a free IP address shows up
PRIVATE_ATTEMPTS=20

# constant
PUBLIC_BRIDGE=br0

# the network interface name as seen from the container
VIF_GUEST=eth0

##############################
## stolen from tests/system/template-qemu/qemu-bridge-init
# use /proc/net/dev instead of a hard-wired list
function gather_interfaces () {
    python <<EOF
for line in file("/proc/net/dev"):
    if ':' not in line: continue
    ifname=line.replace(" ","").split(":")[0]
    if ifname.find("lo")==0: continue
    if ifname.find("br")==0: continue
    if ifname.find("virbr")==0: continue
    if ifname.find("tap")==0: continue
    print ifname
EOF
}

function discover_interface () {
    for ifname in $(gather_interfaces); do
	ip link show $ifname | grep -qi 'state UP' && { echo $ifname; return; }
    done
    # still not found ? that's bad
    echo unknown
}
########## check for a free IP
function ip_is_busy () {
    target=$1; shift
    ping -c 1 -W 1 $target >& /dev/null
}

function random_private_byte () {
    for attempt in $(seq $PRIVATE_ATTEMPTS); do
	byte=$(($RANDOM % 256))
	if [ "$byte" == 0 -o "$byte" == 1 ] ; then continue; fi
	ip=${PRIVATE_PREFIX}${byte}
	ip_is_busy $ip || { echo $byte; return; }
    done
    echo "Cannot seem to find a free IP address in range ${PRIVATE_PREFIX}.xx/24 after $PRIVATE_ATTEMPTS attempts - exiting"
    exit 1
}

########## networking -- ctd
function gethostbyname () {
    hostname=$1
    python -c "import socket; print socket.gethostbyname('"$hostname"')" 2> /dev/null
}

# e.g. 21 -> 255.255.248.0
function masklen_to_netmask () {
    masklen=$1; shift
    python <<EOF
import sys
masklen=$masklen
if not (masklen>=1 and masklen<=32): 
  print "Wrong masklen",masklen
  exit(1)
result=[]
for i in range(4):
    if masklen>=8:
       result.append(8)
       masklen-=8
    else:
       result.append(masklen)
       masklen=0
print ".".join([ str(256-2**(8-i)) for i in result ])
  
EOF
}

#################### bridge initialization
function create_bridge_if_needed() {
   
    # turn on verbosity
    set -x

    # already created ? - we're done
    ip addr show $PUBLIC_BRIDGE >& /dev/null && {
	echo "Bridge already set up - skipping create_bridge_if_needed"
	return 0
    }

    # find out the physical interface to bridge onto
    if_lan=$(discover_interface)

    ip addr show $if_lan &>/dev/null || {
        echo "Cannot use interface $if_lan - exiting"
        exit 1
    }

    #################### bride initialization
    check_yum_installed bridge-utils

    echo "========== $COMMAND: entering create_bridge - beg"
    hostname
    uname -a
    ip addr show
    ip route
    echo "========== $COMMAND: entering create_bridge - end"

    # disable netfilter calls for bridge interface (they cause panick on 2.6.35 anyway)
    #
    # another option would be to accept the all forward packages for
    # bridged interface like: -A FORWARD -m physdev --physdev-is-bridged -j ACCEPT
    sysctl net.bridge.bridge-nf-call-iptables=0
    sysctl net.bridge.bridge-nf-call-ip6tables=0
    sysctl net.bridge.bridge-nf-call-arptables=0

    
    #Getting host IP/masklen
    address=$(ip addr show $if_lan | grep -v inet6 | grep inet | head --lines=1 | awk '{print $2;}')
    [ -z "$address" ] && { echo "ERROR: Could not determine IP address for $if_lan" ; exit 1 ; }

    broadcast=$(ip addr show $if_lan | grep -v inet6 | grep inet | head --lines=1 | awk '{print $4;}')
    [ -z "$broadcast" ] && echo "WARNING: Could not determine broadcast address for $if_lan"

    gateway=$(ip route show | grep default | awk '{print $3;}')
    [ -z "$gateway" ] && echo "WARNING: Could not determine gateway IP"


    # creating the bridge
    echo "Creating bridge PUBLIC_BRIDGE=$PUBLIC_BRIDGE"
    brctl addbr $PUBLIC_BRIDGE
    brctl addif $PUBLIC_BRIDGE $if_lan
    echo "Activating promiscuous mode if_lan=$if_lan"
    ip link set $if_lan up promisc on
    sleep 2
    # rely on dhcp to re assign IP.. 
    echo "Starting dhclient on $PUBLIC_BRIDGE"
    dhclient $PUBLIC_BRIDGE
    sleep 1

    #Reconfigure the routing table
    echo "Configuring gateway=$gateway"
    ip route add default via $gateway dev $PUBLIC_BRIDGE
    ip route del default via $gateway dev $if_lan
    # at this point we have an extra route like e.g.
    ## ip route show
    #default via 138.96.112.250 dev br0
    #138.96.112.0/21 dev em1  proto kernel  scope link  src 138.96.112.57
    #138.96.112.0/21 dev br0  proto kernel  scope link  src 138.96.112.57
    #192.168.122.0/24 dev virbr0  proto kernel  scope link  src 192.168.122.1
    route_dest=$(ip route show | grep -v default | grep "dev $PUBLIC_BRIDGE" | awk '{print $1;}')
    ip route del $route_dest dev $if_lan

    echo "========== $COMMAND: exiting create_bridge - beg"
    ip addr show
    ip route show
    echo "========== $COMMAND: exiting create_bridge - end"

    # for safety
    sleep 3
    return 0

}


##############################
function check_yum_installed () {
    package=$1; shift
    rpm -q $package >& /dev/null || yum -y install $package
}

function check_yumgroup_installed () {
    group="$1"; shift
    yum grouplist "$group" | grep -q Installed || { yum -y groupinstall "$group" ; }
}

##############################

function configure_fedora() {

    # disable selinux in fedora
    mkdir -p $rootfs_path/selinux
    echo 0 > $rootfs_path/selinux/enforce

    # set the hostname
    case "$fcdistro" in 
	f18|f2?)
	    cat <<EOF > ${rootfs_path}/etc/hostname
$GUEST_HOSTNAME
EOF
	    echo ;;
	*)
            cat <<EOF > ${rootfs_path}/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=$GUEST_HOSTNAME
EOF
            # set minimal hosts
	    cat <<EOF > $rootfs_path/etc/hosts
127.0.0.1 localhost $GUEST_HOSTNAME
EOF
	    echo ;;
    esac

    dev_path="${rootfs_path}/dev"
    rm -rf $dev_path
    mkdir -p $dev_path
    mknod -m 666 ${dev_path}/null c 1 3
    mknod -m 666 ${dev_path}/zero c 1 5
    mknod -m 666 ${dev_path}/random c 1 8
    mknod -m 666 ${dev_path}/urandom c 1 9
    mkdir -m 755 ${dev_path}/pts
    mkdir -m 1777 ${dev_path}/shm
    mknod -m 666 ${dev_path}/tty c 5 0
    mknod -m 666 ${dev_path}/tty0 c 4 0
    mknod -m 666 ${dev_path}/tty1 c 4 1
    mknod -m 666 ${dev_path}/tty2 c 4 2
    mknod -m 666 ${dev_path}/tty3 c 4 3
    mknod -m 666 ${dev_path}/tty4 c 4 4
    mknod -m 600 ${dev_path}/console c 5 1
    mknod -m 666 ${dev_path}/full c 1 7
    mknod -m 600 ${dev_path}/initctl p
    mknod -m 666 ${dev_path}/ptmx c 5 2

    #echo "setting root passwd to $root_password"
    #echo "root:$root_password" | chroot $rootfs_path chpasswd

    return 0
}

function configure_fedora_init() {

    sed -i 's|.sbin.start_udev||' ${rootfs_path}/etc/rc.sysinit
    sed -i 's|.sbin.start_udev||' ${rootfs_path}/etc/rc.d/rc.sysinit
    # don't mount devpts, for pete's sake
    sed -i 's/^.*dev.pts.*$/#\0/' ${rootfs_path}/etc/rc.sysinit
    sed -i 's/^.*dev.pts.*$/#\0/' ${rootfs_path}/etc/rc.d/rc.sysinit
    chroot ${rootfs_path} /sbin/chkconfig udev-post off
    chroot ${rootfs_path} /sbin/chkconfig network on
}

# this code of course is for guests that do run on systemd
function configure_fedora_systemd() {
    # so ignore if we can't find /etc/systemd at all 
    [ -d ${rootfs_path}/etc/systemd ] || return 0
    # otherwise let's proceed
    ln -sf /lib/systemd/system/multi-user.target ${rootfs_path}/etc/systemd/system/default.target
    touch ${rootfs_path}/etc/fstab
    ln -sf /dev/null ${rootfs_path}/etc/systemd/system/udev.service
# Thierry - Feb 2013
# this was intended for f16 initially, in order to enable getty that otherwise would not start
# having a getty running is helpful only if ssh won't start though, and we see a correlation between
# VM's that refuse to lxc-stop and VM's that run crazy getty's
# so, turning getty off for now instead
#   #dependency on a device unit fails it specially that we disabled udev
#    sed -i 's/After=dev-%i.device/After=/' ${rootfs_path}/lib/systemd/system/getty\@.service
    ln -sf /dev/null ${rootfs_path}/etc/systemd/system/"getty@.service"
    rm -f ${rootfs_path}/etc/systemd/system/getty.target.wants/*service || :
# can't seem to handle this one with systemctl
    chroot ${rootfs_path} /sbin/chkconfig network on
}

function download_fedora() {
set -x
    # check the mini fedora was not already downloaded
    INSTALL_ROOT=$cache/partial
    echo $INSTALL_ROOT

    # download a mini fedora into a cache
    echo "Downloading fedora minimal ..."

    mkdir -p $INSTALL_ROOT
    if [ $? -ne 0 ]; then
        echo "Failed to create '$INSTALL_ROOT' directory"
        return 1
    fi

    mkdir -p $INSTALL_ROOT/etc/yum.repos.d   
    mkdir -p $INSTALL_ROOT/dev
    mknod -m 0444 $INSTALL_ROOT/dev/random c 1 8
    mknod -m 0444 $INSTALL_ROOT/dev/urandom c 1 9

    # copy yum config and repo files
    cp /etc/yum.conf $INSTALL_ROOT/etc/
    cp /etc/yum.repos.d/fedora* $INSTALL_ROOT/etc/yum.repos.d/

    # append fedora repo files with desired $release and $basearch
    for f in $INSTALL_ROOT/etc/yum.repos.d/*
    do
      sed -i "s/\$basearch/$arch/g; s/\$releasever/$release/g;" $f
    done 

    MIRROR_URL=http://mirror.onelab.eu/fedora/releases/$release/Everything/$arch/os
    RELEASE_URL1="$MIRROR_URL/Packages/fedora-release-$release-1.noarch.rpm"
    # with fedora18 the rpms are scattered by first name
    RELEASE_URL2="$MIRROR_URL/Packages/f/fedora-release-$release-1.noarch.rpm"
    RELEASE_TARGET=$INSTALL_ROOT/fedora-release-$release.noarch.rpm
    found=""
    for attempt in $RELEASE_URL1 $RELEASE_URL2; do
	if curl -f $attempt -o $RELEASE_TARGET ; then
	    echo "Retrieved $attempt"
	    found=true
	    break
	else
	    echo "Failed attempt $attempt"
	fi
    done
    [ -n "$found" ] || { echo "Could not retrieve fedora-release rpm - exiting" ; exit 1; }
    
    mkdir -p $INSTALL_ROOT/var/lib/rpm
    rpm --root $INSTALL_ROOT  --initdb
    # when installing f12 this apparently is already present, so ignore result
    rpm --root $INSTALL_ROOT -ivh $INSTALL_ROOT/fedora-release-$release.noarch.rpm || :
    # however f12 root images won't get created on a f18 host
    # (the issue here is the same as the one we ran into when dealing with a vs-box)
    # in a nutshell, in f12 the glibc-common and filesystem rpms have an apparent conflict
    # >>> file /usr/lib/locale from install of glibc-common-2.11.2-3.x86_64 conflicts 
    #          with file from package filesystem-2.4.30-2.fc12.x86_64
    # in fact this was - of course - allowed by f12's rpm but later on a fix was made 
    #   http://rpm.org/gitweb?p=rpm.git;a=commitdiff;h=cf1095648194104a81a58abead05974a5bfa3b9a
    # So ideally if we want to be able to build f12 images from f18 we need an rpm that has
    # this patch undone, like we have in place on our f14 boxes (our f14 boxes need a f18-like rpm)

    YUM="yum --installroot=$INSTALL_ROOT --nogpgcheck -y"
    PKG_LIST="yum initscripts passwd rsyslog vim-minimal dhclient chkconfig rootfiles policycoreutils openssh-server openssh-clients"
    echo "$YUM install $PKG_LIST"
    $YUM install $PKG_LIST

    if [ $? -ne 0 ]; then
        echo "Failed to download the rootfs, aborting."
        return 1
    fi

    mv "$INSTALL_ROOT" "$cache/rootfs"
    echo "Download complete."

    return 0
}


function copy_fedora() {
set -x
    # make a local copy of the minifedora
    echo -n "Copying rootfs to $rootfs_path ..."
    mkdir -p $rootfs_path
    rsync -a $cache/rootfs/ $rootfs_path/
    return 0
}


function update_fedora() {
set -x
    YUM="yum --installroot $cache/rootfs -y --nogpgcheck"
    $YUM update
}


function install_fedora() {
    set -x

    mkdir -p /var/lock/subsys/
    (
        flock -n -x 200
        if [ $? -ne 0 ]; then
            echo "Cache repository is busy."
            return 1
        fi

        echo "Checking cache download in $cache/rootfs ... "
        if [ ! -e "$cache/rootfs" ]; then
            download_fedora
            if [ $? -ne 0 ]; then
                echo "Failed to download 'fedora base'"
                return 1
            fi
        else
            echo "Cache found. Updating..."
            update_fedora
            if [ $? -ne 0 ]; then
                echo "Failed to update 'fedora base', continuing with last known good cache"
            else
                echo "Update finished"
            fi
        fi

        echo "Copy $cache/rootfs to $rootfs_path ... "
        copy_fedora
        if [ $? -ne 0 ]; then
            echo "Failed to copy rootfs"
            return 1
        fi

        return 0

        ) 200>/var/lock/subsys/lxc

    return $?
}


# overwrite lxc's internal yum config
function configure_yum_in_lxc () {
    set -x 
    set -e 
    trap failure ERR INT

    lxc=$1; shift
    fcdistro=$1; shift
    pldistro=$1; shift

    echo "Initializing yum.repos.d in $lxc"
    rm -f $rootfs_path/etc/yum.repos.d/*

    cat > $rootfs_path/etc/yum.repos.d/building.repo <<EOF
[fedora]
name=Fedora $release - $arch
baseurl=http://mirror.onelab.eu/fedora/releases/$release/Everything/$arch/os/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=http://mirror.onelab.eu/keys/RPM-GPG-KEY-fedora-$release-primary

[updates]
name=Fedora $release - $arch - Updates
baseurl=http://mirror.onelab.eu/fedora/updates/$release/$arch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=http://mirror.onelab.eu/keys/RPM-GPG-KEY-fedora-$release-primary
EOF
    
    # for using vtest-init-lxc.sh as a general-purpose lxc creation wrapper
    # just mention 'none' as the repo url
    if [ -n "$REPO_URL" ] ; then
	if [ ! -d $rootfs_path/etc/yum.repos.d ] ; then
	    echo "WARNING : cannot create myplc repo"
	else
            # exclude kernel from fedora repos 
	    yumexclude=$(pl_plcyumexclude $fcdistro $pldistro $DIRNAME)
	    for repo in $rootfs_path/etc/yum.repos.d/* ; do
		[ -f $repo ] && yumconf_exclude $repo "exclude=$yumexclude" 
	    done
	    # the build repo is not signed at this stage
	    cat > $rootfs_path/etc/yum.repos.d/myplc.repo <<EOF
[myplc]
name= MyPLC
baseurl=$REPO_URL
enabled=1
gpgcheck=0
EOF
	fi
    fi
}    

# return yum or debootstrap
function package_method () {
    fcdistro=$1; shift
    case $fcdistro in
	f[0-9]*|centos[0-9]*|sl[0-9]*) echo yum ;;
	squeeze|wheezy|oneiric|precise|quantal|raring|saucy) echo debootstrap ;;
	*) echo Unknown distro $fcdistro ;;
    esac 
}

# return arch from debian distro and personality
function canonical_arch () {
    personality=$1; shift
    fcdistro=$1; shift
    case $(package_method $fcdistro) in
	yum)
	    case $personality in *32) echo i386 ;; *64) echo x86_64 ;; *) echo Unknown-arch-1 ;; esac ;;
	debootstrap)
	    case $personality in *32) echo i386 ;; *64) echo amd64 ;; *) echo Unknown-arch-2 ;; esac ;;
	*)
	    echo Unknown-arch-3 ;;
    esac
}

# the new test framework creates /timestamp in /vservers/<name> *before* populating it
function almost_empty () { 
    dir="$1"; shift ; 
    # non existing is fine
    [ ! -d $dir ] && return 0; 
    # need to have at most one file
    count=$(cd $dir; ls | wc -l); [ $count -le 1 ]; 
}

function setup_lxc() {

    set -x
    set -e
    #trap failure ERR INT

    lxc=$1; shift
    fcdistro=$1; shift
    pldistro=$1; shift
    personality=$1; shift

    # create lxc container 
    
    pkg_method=$(package_method $fcdistro)
    case $pkg_method in
	yum)
	    install_fedora || { echo "failed to install fedora"; exit 1 ; }
	    configure_fedora || { echo "failed to configure fedora for a container"; exit 1 ; }
	    if [ "$(echo $fcdistro | cut -d"f" -f2)" -le "14" ]; then
		configure_fedora_init
	    else
		configure_fedora_systemd
	    fi
	    ;;
	debootstrap)
	    echo "$COMMAND: no support for debootstrap-based systems - yet"
	    exit 1
	    ;;
	*)
	    echo "$COMMAND:: unknown package_method - exiting"
	    exit 1
	    ;;
    esac

    # rpm --rebuilddb
    chroot $rootfs_path /bin/rpm --rebuilddb

    configure_yum_in_lxc $lxc $fcdistro $pldistro

    # Enable cgroup -- xxx -- is this really useful ?
    mkdir $rootfs_path/cgroup
    
    # set up resolv.conf
    cp /etc/resolv.conf $rootfs_path/etc/resolv.conf
    # and /etc/hosts for at least localhost
    [ -f $rootfs_path/etc/hosts ] || echo "127.0.0.1 localhost localhost.localdomain" > $rootfs_path/etc/hosts
    
    # grant ssh access from host to guest
    mkdir $rootfs_path/root/.ssh
    cat /root/.ssh/id_rsa.pub >> $rootfs_path/root/.ssh/authorized_keys
    
    config_xml=$config_path/"lxc.xml"
    guest_ifcfg=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-$VIF_GUEST
    if [ -n "$BUILD_MODE" ] ; then
	write_lxc_xml_build $lxc > $config_xml
	write_guest_ifcfg_build > $guest_ifcfg
    else
	write_lxc_xml_test $lxc > $config_xml
	write_guest_ifcfg_test > $guest_ifcfg
    fi
    
    # define lxc container for libvirt
    virsh -c lxc:// define $config_xml

    return 0
}

function write_lxc_xml_test () {
    lxc=$1; shift
    cat <<EOF
<domain type='lxc'>
  <name>$lxc</name>
  <memory>524288</memory>
  <os>
    <type arch='$arch2'>exe</type>
    <init>/sbin/init</init>
  </os>
  <features>
    <acpi/>
  </features>
  <vcpu>1</vcpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/libexec/libvirt_lxc</emulator>
    <filesystem type='mount'>
      <source dir='$rootfs_path'/>
      <target dir='/'/>
    </filesystem>
    <interface type="bridge">
      <source bridge="$BRIDGE_IF"/>
      <target dev='$VIF_HOST'/>
    </interface>
    <console type='pty' />
  </devices>
  <network>
    <name>host-bridge</name>
    <forward mode="bridge"/>
    <bridge name="$BRIDGE_IF"/>
  </network>
</domain>
EOF
}

function write_lxc_xml_build () { 
    lxc=$1; shift
    cat <<EOF
<domain type='lxc'>
  <name>$lxc</name>
  <memory>524288</memory>
  <os>
    <type arch='$arch2'>exe</type>
    <init>/sbin/init</init>
  </os>
  <features>
    <acpi/>
  </features>
  <vcpu>1</vcpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/libexec/libvirt_lxc</emulator>
    <filesystem type='mount'>
      <source dir='$rootfs_path'/>
      <target dir='/'/>
    </filesystem>
    <interface type="network">
      <source network="default"/>
    </interface>
    <console type='pty' />
  </devices>
</domain>
EOF
}

# this one is dhcp-based
function write_guest_ifcfg_build () {
    cat <<EOF
DEVICE=$VIF_GUEST
BOOTPROTO=dhcp
ONBOOT=yes
NM_CONTROLLED=no
TYPE=Ethernet
MTU=1500
EOF
}

# use fixed IP as specified by GUEST_HOSTNAME
function write_guest_ifcfg_test () {
    cat <<EOF
DEVICE=$VIF_GUEST
BOOTPROTO=static
ONBOOT=yes
HOSTNAME=$GUEST_HOSTNAME
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
NM_CONTROLLED=no
TYPE=Ethernet
MTU=1500
EOF
}

function devel_or_vtest_tools () {

    set -x 
    set -e 
    trap failure ERR INT

    lxc=$1; shift
    fcdistro=$1; shift
    pldistro=$1; shift
    personality=$1; shift

    pkg_method=$(package_method $fcdistro)

    pkgsfile=$(pl_locateDistroFile $DIRNAME $pldistro $PREINSTALLED)

    ### install individual packages, then groups
    # get target arch - use uname -i here (we want either x86_64 or i386)
   
    lxc_arch=$(chroot $rootfs_path /bin/uname -i)
    # on debian systems we get arch through the 'arch' command
    [ "$lxc_arch" = "unknown" ] && lxc_arch=$(chroot $rootfs_path /bin/arch)

    packages=$(pl_getPackages -a $lxc_arch $fcdistro $pldistro $pkgsfile)
    groups=$(pl_getGroups -a $lxc_arch $fcdistro $pldistro $pkgsfile)

    case "$pkg_method" in
	yum)
	    [ -n "$packages" ] && chroot $rootfs_path /usr/bin/yum -y install $packages
	    for group_plus in $groups; do
		group=$(echo $group_plus | sed -e "s,+++, ,g")
		chroot $rootfs_path /usr/bin/yum -y groupinstall "$group"
	    done
	    # store current rpm list in /init-lxc.rpms in case we need to check the contents
	    chroot $rootfs_path /bin/rpm -aq > $rootfs_path/init-lxc.rpms
	    ;;
	debootstrap)
	    chroot $rootfs_path /usr/bin/apt-get update
	    for package in $packages ; do 
	        chroot $rootfs_path  /usr/bin/apt-get install -y $package 
	    done
	    ### xxx todo install groups with apt..
	    ;;
	*)
	    echo "unknown pkg_method $pkg_method"
	    ;;
    esac

    return 0
}

function post_install () {
    lxc=$1; shift 
    personality=$1; shift
    if [ -n "$BUILD_MODE" ] ; then
	post_install_build $lxc $personality
	lxc_start $lxc
	# manually run dhclient in guest - somehow this network won't start on its own
	virsh lxc-enter-namespace $lxc /usr/sbin/dhclient $VIF_GUEST
    else
	post_install_myplc $lxc $personality
	lxc_start $lxc
	wait_for_ssh $lxc
    fi
    # setup localtime from the host
    cp /etc/localtime $rootfs_path/etc/localtime
}

function post_install_build () {

    set -x 
    set -e 
    trap failure ERR INT

    lxc=$1; shift
    personality=$1; shift

### From myplc-devel-native.spec
# be careful to backslash $ in this, otherwise it's the root context that's going to do the evaluation
    cat << EOF | chroot $rootfs_path /bin/bash -x
    # set up /dev/loop* in lxc
    for i in \$(seq 0 255) ; do
	/bin/mknod -m 640 /dev/loop\$i b 7 \$i
    done
    
    # create symlink for /dev/fd
    [ ! -e "/dev/fd" ] && /bin/ln -s /proc/self/fd /dev/fd

    # modify /etc/rpm/macros to not use /sbin/new-kernel-pkg
    /bin/sed -i 's,/sbin/new-kernel-pkg:,,' /etc/rpm/macros
    if [ -h "/sbin/new-kernel-pkg" ] ; then
	filename=\$(/bin/readlink -f /sbin/new-kernel-pkg)
	if [ "\$filename" == "/sbin/true" ] ; then
		/bin/echo "WARNING: /sbin/new-kernel-pkg symlinked to /sbin/true"
		/bin/echo "\tmost likely /etc/rpm/macros has /sbin/new-kernel-pkg declared in _netsharedpath."
		/bin/echo "\tPlease remove /sbin/new-kernel-pkg from _netsharedpath and reintall mkinitrd."
		exit 1
	fi
    fi
    
    # customize root's prompt
    /bin/cat << PROFILE > /root/.profile
export PS1="[$lxc] \\w # "
PROFILE

    uid=2000
    gid=2000
    
    # add a "build" user to the system
    builduser=\$(grep "^build:" /etc/passwd | wc -l)
    if [ \$builduser -eq 0 ] ; then
	groupadd -o -g \$gid build;
	useradd -o -c 'Automated Build' -u \$uid -g \$gid -n -M -s /bin/bash build;
    fi

# Allow build user to build certain RPMs as root
    if [ -f /etc/sudoers ] ; then
	buildsudo=\$(grep "^build.*ALL=(ALL).*NOPASSWD:.*ALL"  /etc/sudoers | wc -l)
	if [ \$buildsudo -eq 0 ] ; then
	    echo "build   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
	fi
        sed -i 's,^Defaults.*requiretty,#Defaults requiretty,' /etc/sudoers
    fi
#
EOF
	
}

function post_install_myplc  () {
    set -x 
    set -e 
    trap failure ERR INT

    lxc=$1; shift
    personality=$1; shift

# be careful to backslash $ in this, otherwise it's the root context that's going to do the evaluation
    cat << EOF | chroot $rootfs_path /bin/bash -x

    # create /etc/sysconfig/network if missing
    [ -f /etc/sysconfig/network ] || /bin/echo NETWORKING=yes > /etc/sysconfig/network

    # create symlink for /dev/fd
    [ ! -e "/dev/fd" ] && /bin/ln -s /proc/self/fd /dev/fd

    # turn off regular crond, as plc invokes plc_crond
    /sbin/chkconfig crond off

    # take care of loginuid in /etc/pam.d 
    /bin/sed -i "s,#*\(.*loginuid.*\),#\1," /etc/pam.d/*

    # customize root's prompt
    /bin/cat << PROFILE > /root/.profile
export PS1="[$lxc] \\w # "
PROFILE

EOF
}

function lxc_start() {

    set -x
    set -e
    #trap failure ERR INT

    lxc=$1; shift
  
    virsh -c lxc:// start $lxc
  
    return 0
}

function wait_for_ssh () {
    set -x
    set -e
    #trap failure ERR INT

    lxc=$1; shift
  
    echo $IP is up, waiting for ssh...

    #wait max 5 min for sshd to start 
    ssh_up=""
    stop_time=$(($(date +%s) + 300))
    current_time=$(date +%s)
    
    counter=1
    while [ "$current_time" -lt "$stop_time" ] ; do
         echo "$counter-th attempt to reach sshd in container $lxc ..."
         ssh -o "StrictHostKeyChecking no" $IP 'uname -i' && { ssh_up=true; echo "SSHD in container $lxc is UP"; break ; } || :
         sleep 10
         current_time=$(($current_time + 10))
         counter=$(($counter+1))
    done

    # Thierry: this is fatal, let's just exit with a failure here
    [ -z $ssh_up ] && { echo "SSHD in container $lxc is not running" ; exit 1 ; } 
    return 0
}

####################
function failure () {
    echo "$COMMAND : Bailing out"
    exit 1
}

function usage () {
    set +x 
    echo "Usage: $COMMAND_LBUILD [options] lxc-name"
    echo "Usage: $COMMAND_LTEST [options] lxc-name"
    echo "Description:"
    echo "   This command creates a fresh lxc instance, for building, or running a test myplc"
    echo "Supported options"
    echo " -f fcdistro - for creating the root filesystem - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -n hostname - the hostname to use in container - required with $COMMAND_LTEST"
    echo " -r repo-url - used to populate yum.repos.d - required with $COMMAND_LTEST"
    echo " -P pkgs_file - defines the set of extra pacakges"
    echo "    by default we use vtest.pkgs or devel.pkgs according to $COMMAND"
    echo " -v be verbose"
    exit 1
}

### parse args and 
function main () {

    #set -e
    #trap failure ERR INT

    if [ "$(id -u)" != "0" ]; then
          echo "This script should be run as 'root'"
          exit 1
    fi

    case "$COMMAND" in
	$COMMAND_LBUILD)
	    BUILD_MODE=true ;;
	$COMMAND_LTEST)
	    TEST_MODE=true;;
	*)
	    usage ;;
    esac

    echo 'build mode=' $BUILD_MODE 'test mode=' $TEST_MODE

    # the set of preinstalled packages - depends on vbuild or vtest
    if [ -n "$BUILD_MODE" ] ; then
	PREINSTALLED=devel.pkgs
    else
	PREINSTALLED=vtest.pkgs
    fi
    while getopts "f:d:p:n:r:P:v" opt ; do
	case $opt in
	    f) fcdistro=$OPTARG;;
	    d) pldistro=$OPTARG;;
	    p) personality=$OPTARG;;
	    n) GUEST_HOSTNAME=$OPTARG;;
	    r) REPO_URL=$OPTARG;;
	    P) PREINSTALLED=$OPTARG;;
	    v) VERBOSE=true; set -x;;
	    *) usage ;;
	esac
    done
	
    shift $(($OPTIND - 1))

    # parse fixed arguments
    [[ -z "$@" ]] && usage
    lxc=$1 ; shift

    # check we've exhausted the arguments
    [[ -n "$@" ]] && usage

    [ -z "$fcdistro" ] && fcdistro=$DEFAULT_FCDISTRO
    [ -z "$pldistro" ] && pldistro=$DEFAULT_PLDISTRO
    [ -z "$personality" ] && personality=$DEFAULT_PERSONALITY
    
    if [ -n "$BUILD_MODE" ] ; then
        [ -z "$GUEST_HOSTNAME" ] && GUEST_HOSTNAME=$lxc
    else
	[[ -z "$GUEST_HOSTNAME" ]] && usage
	# use -r none to get rid of this warning
	if [ "$REPO_URL" == "none" ] ; then
	    REPO_URL=""
	elif [ -z "$REPO_URL" ] ; then
	    echo "WARNING -- setting up a yum repo is recommended" 
	fi
    fi

    ##########
    release=$(echo $fcdistro | cut -df -f2)

    if [ "$personality" == "linux32" ]; then
        arch=i386
        arch2=i686
    elif [ "$personality" == "linux64" ]; then
        arch=x86_64
        arch2=x86_64
    else
        echo "Unknown personality: $personality"
    fi

    if [ -n "$BUILD_MODE" ] ; then

	# Bridge IP affectation
	byte=$(random_private_byte)
	IP=${PRIVATE_PREFIX}$byte
	NETMASK=$(masklen_to_netmask $PRIVATE_MASKLEN)
	GATEWAY=$PRIVATE_GATEWAY
	VIF_HOST="i$byte"
	BRIDGE_MODE="nat"
	BRIDGE_IF="$PRIVATE_BRIDGE"
    else
        [[ -z "GUEST_HOSTNAME" ]] && usage
       
	create_bridge_if_needed

	IP=$(gethostbyname $GUEST_HOSTNAME)
	# use same NETMASK as bridge interface br0
	MASKLEN=$(ip addr show $PUBLIC_BRIDGE | grep -v inet6 | grep inet | awk '{print $2;}' | cut -d/ -f2)
        NETMASK=$(masklen_to_netmask $MASKLEN)
        GATEWAY=$(ip route show | grep default | awk '{print $3}')
        VIF_HOST="i$(echo $GUEST_HOSTNAME | cut -d. -f1)"
	BRIDGE_MODE="bridge"
	BRIDGE_IF="PUBLIC_BRIDGE"
    fi

    echo "the IP address of container $lxc is $IP, host virtual interface is $VIF_HOST"

    path=/vservers
    [ ! -d $path ] && mkdir $path
    rootfs_path=$path/$lxc/rootfs
    config_path=$path/$lxc
    cache_base=/var/cache/lxc/fedora/$arch
    cache=$cache_base/$release
    root_password=root
    
    # check whether the rootfs directory is created to know if the container exists
    # bacause /var/lib/lxc/$lxc is already created while putting $lxc.timestamp
    [ -d $rootfs_path ] && \
	{ echo "container $lxc already exists in filesystem - exiting" ; exit 1 ; }
    virsh --connect lxc:// domuuid $lxc >& /dev/null && \
	{ echo "container $lxc already exists in libvirt - exiting" ; exit 1 ; }

    setup_lxc $lxc $fcdistro $pldistro $personality 

    devel_or_vtest_tools $lxc $fcdistro $pldistro $personality

    post_install $lxc $personality
    
    echo $COMMAND Done
}

main "$@"
