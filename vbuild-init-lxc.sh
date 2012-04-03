#!/bin/bash
# -*-shell-*-

#shopt -s huponexit

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)
BUILD_DIR=$(pwd)

# pkgs parsing utilities
PATH=$(dirname $0):$PATH export PATH
. build.common

DEFAULT_FCDISTRO=f16
DEFAULT_PLDISTRO=planetlab
DEFAULT_PERSONALITY=linux64
DEFAULT_IFNAME=eth0

COMMAND_VBUILD="vbuild-init-lxc.sh"
COMMAND_MYPLC="vtest-init-lxc.sh"

lxc_version="0.8.0-rc2"

function bridge_init () {

    # turn on verbosity
    set -x

    # constant
    INTERFACE_BRIDGE=br0

    # Default Value for INTERFACE_LAN
    INTERFACE_LAN=$(netstat -rn | grep '^0.0.0.0' | awk '{print $8;}')


    echo "========== $COMMAND: entering start - beg"
    hostname
    uname -a
    ifconfig
    netstat -rn
    echo "========== $COMMAND: entering start - end"

    # disable netfilter calls for bridge interface (they cause panick on 2.6.35 anyway)
    #
    # another option would be to accept the all forward packages for
    # bridged interface like: -A FORWARD -m physdev --physdev-is-bridged -j ACCEPT
    sysctl net.bridge.bridge-nf-call-iptables=0
    sysctl net.bridge.bridge-nf-call-ip6tables=0
    sysctl net.bridge.bridge-nf-call-arptables=0

    # take extra arg for ifname, if provided
    [ -n "$1" ] && { INTERFACE_LAN=$1; shift ; }

    #if we have already configured the same host_box no need to do it again
    /sbin/ifconfig $INTERFACE_BRIDGE &> /dev/null && {
        echo "Bridge interface $INTERFACE_BRIDGE already set up - $COMMAND start exiting"
        return 0
    }
    /sbin/ifconfig $INTERFACE_LAN &>/dev/null || {
        echo "Cannot use interface $INTERFACE_LAN - exiting"
        exit 1
    }

    
    #Getting host IP/masklen
    address=$(/sbin/ip addr show $INTERFACE_LAN | grep -v inet6 | grep inet | head --lines=1 | awk '{print $2;}')
    [ -z "$address" ] && { echo "ERROR: Could not determine IP address for $INTERFACE_LAN" ; exit 1 ; }

broadcast=$(/sbin/ip addr show $INTERFACE_LAN | grep -v inet6 | grep inet | head --lines=1 | awk '{print $4;}')
    [ -z "$broadcast" ] && echo "WARNING: Could not determine broadcast address for $INTERFACE_LAN"

    gateway=$(netstat -rn | grep '^0.0.0.0' | awk '{print $2;}')
    [ -z "$gateway" ] && echo "WARNING: Could not determine gateway IP"

    # creating the bridge
    echo "Creating bridge INTERFACE_BRIDGE=$INTERFACE_BRIDGE"
    brctl addbr $INTERFACE_BRIDGE
    #brctl stp $INTERFACE_BRIDGE yes
    brctl addif $INTERFACE_BRIDGE $INTERFACE_LAN
    echo "Activating promiscuous mode INTERFACE_LAN=$INTERFACE_LAN"
    /sbin/ifconfig $INTERFACE_LAN 0.0.0.0 promisc up
    sleep 2
    echo "Setting bridge address=$address broadcast=$broadcast"
    # static
    /sbin/ifconfig $INTERFACE_BRIDGE $address broadcast $broadcast up
    sleep 1

    #Reconfigure the routing table
    echo "Configuring gateway=$gateway"
    route add default gw $gateway

    echo "========== $COMMAND: exiting start - beg"
    ifconfig
    netstat -rn
    echo "========== $COMMAND: exiting start - end"


return 0

}


function failure () {
    echo "$COMMAND : Bailing out"
    exit 1
}

function cidr_notation () {

netmask=$1; shift
cidr=0
for i in $(seq 1 4) ; do
    part=$(echo $netmask | cut -d. -f $i)
    case $part in
        "255") cidr=$((cidr + 8));;
        "254") cidr=$((cidr + 7));;
        "252") cidr=$((cidr + 6));;
        "248") cidr=$((cidr + 5));;
        "240") cidr=$((cidr + 4));;
        "224") cidr=$((cidr + 3));;
        "192") cidr=$((cidr + 2));;
        "128") cidr=$((cidr + 1));;
        "0") cidr=$((cidr + 0));;
     esac
done
echo $cidr

}

function check_yum_installed () {
    package=$1; shift
    rpm -q $package >& /dev/null || yum -y install $package
}

function check_yumgroup_installed () {
    group="$1"; shift
    yum grouplist "$group" | grep -q Installed || { yum -y groupinstall "$group" ; }
}

function prepare_host() {
        
    #################### lxc-tools : rebuild as current fedora release has flaws
    #install development tools
    check_yumgroup_installed "Development Tools"
    #install libcap-devel, libvirt
    check_yum_installed libcap-devel
    check_yum_installed libvirt

    #retrieve and install lxc from sources 
    #raw_version=$(lxc-version ||: )
    #lxc_installed_version=$(echo $raw_version | sed -e 's,.*: ,,')
    #if [ "$lxc_installed_version" != "$lxc_version" ] ; then
    if [ ! -f /usr/bin/lxc-ls ] ; then
	#echo "Expecting version" '['$lxc_version']'
	#echo "Found version" '['$lxc_installed_version']'
        echo "Installing lxc ..."
        cd /root
	[ -d lxc ] || git clone git://lxc.git.sourceforge.net/gitroot/lxc/lxc 
        cd lxc
	git pull
	git checkout $lxc_version
        ./autogen.sh
        ./configure --prefix=/usr --exec-prefix=/usr
        make
        make install
        mkdir -p /usr/var/lib/
        [ -d /usr/var/lib/lxc ] || ln -s /var/lib/lxc /usr/var/lib/lxc
	cd $BUILD_DIR
    fi
 
#    #create a placeholder (just a hack to make lxc works)
#    [ -d "/usr/local/var/lib" ] || mkdir -p /usr/local/var/lib

    #################### bride initialization
    check_yum_installed bridge-utils
    #Bridge init
    isInstalled=$(netstat -rn | grep '^0.0.0.0' | awk '{print $8;}')
    if [ "$isInstalled" != "br0" ] ; then
	bridge_init
        sleep 5
    fi

    return 0
}



function configure_fedora() {

    # disable selinux in fedora
    mkdir -p $rootfs_path/selinux
    echo 0 > $rootfs_path/selinux/enforce

   # configure the network 

    cat <<EOF > ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-$IFNAME
DEVICE=$IFNAME
BOOTPROTO=static
ONBOOT=yes
HOSTNAME=$HOSTNAME
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
NM_CONTROLLED=no
TYPE=Ethernet
MTU=1500
EOF

# set the hostname
    cat <<EOF > ${rootfs_path}/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=$HOSTNAME
EOF

    # set minimal hosts
#    cat <<EOF > $rootfs_path/etc/hosts
#127.0.0.1 localhost $HOSTNAME
#EOF

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
    chroot ${rootfs_path} chkconfig udev-post off
    chroot ${rootfs_path} chkconfig network on
}


function configure_fedora_systemd() {

    unlink ${rootfs_path}/etc/systemd/system/default.target
    touch ${rootfs_path}/etc/fstab
    chroot ${rootfs_path} ln -s /dev/null //etc/systemd/system/udev.service
    chroot ${rootfs_path} ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
    #dependency on a device unit fails it specially that we disabled udev
    sed -i 's/After=dev-%i.device/After=/' ${rootfs_path}/lib/systemd/system/getty\@.service
    chroot ${rootfs_path} chkconfig network on
}

function download_fedora() {
set -x
    # check the mini fedora was not already downloaded
    INSTALL_ROOT=$cache/partial
    echo $INSTALL_ROOT
    mkdir -p $INSTALL_ROOT
    if [ $? -ne 0 ]; then
        echo "Failed to create '$INSTALL_ROOT' directory"
        return 1
    fi

    # download a mini fedora into a cache
    echo "Downloading fedora minimal ..."
    YUM="yum --installroot $INSTALL_ROOT -y --nogpgcheck --releasever=$release"
    PKG_LIST="yum initscripts passwd rsyslog vim-minimal dhclient chkconfig rootfiles policycoreutils openssh-server openssh-clients"
  
    
    MIRROR_URL=http://mirror.onelab.eu/fedora/releases/$release/Everything/$arch/os
    RELEASE_URL="$MIRROR_URL/Packages/fedora-release-$release-1.noarch.rpm"
    echo "Fetching from $RELEASE_URL"
    curl -f "$RELEASE_URL" > $INSTALL_ROOT/fedora-release-$release.noarch.rpm
    
    mkdir -p $INSTALL_ROOT/var/lib/rpm
    rpm --root $INSTALL_ROOT  --initdb
    rpm --root $INSTALL_ROOT -ivh $INSTALL_ROOT/fedora-release-$release.noarch.rpm
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


function copy_configuration() {

    mkdir -p $config_path
    cat <<EOF >> $config_path/config
lxc.utsname = $lxc
lxc.arch = $arch2
lxc.tty = 4
lxc.pts = 1024
lxc.rootfs = $rootfs_path
lxc.mount  = $config_path/fstab
#networking
lxc.network.type = $lxc_network_type
lxc.network.flags = up
lxc.network.link = $lxc_network_link
lxc.network.name = $IFNAME
lxc.network.mtu = 1500
lxc.network.ipv4 = $IP/$CIDR
#cgroups
#lxc.cgroup.devices.deny = a
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm
lxc.cgroup.devices.allow = b 255:0 rwm
EOF



    cat <<EOF > $config_path/fstab
proc            $rootfs_path/proc         proc    nodev,noexec,nosuid 0 0
devpts          $rootfs_path/dev/pts      devpts defaults 0 0
sysfs           $rootfs_path/sys          sysfs defaults  0 0
EOF
    if [ $? -ne 0 ]; then
        echo "Failed to add configuration"
        return 1
    fi

    return 0
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
name=Fedora $release - \$basearch
baseurl=http://mirror.onelab.eu/fedora/releases/$release/Everything/\$basearch/os/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=http://mirror.onelab.eu/keys/RPM-GPG-KEY-fedora-$release-primary

[updates]
name=Fedora $release - \$basearch - Updates
baseurl=http://mirror.onelab.eu/fedora/updates/$release/\$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=http://mirror.onelab.eu/keys/RPM-GPG-KEY-fedora-$release-primary
EOF
    
    # for using vtest-init-lxc.sh as a general-purpose lxc creation wrapper
    # just mention 'none' as the repo url
    if [ -n "$MYPLC_MODE" -a "$REPO_URL" != "none" ] ; then
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
	lenny|etch) echo debootstrap ;;
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
    copy_configuration
    if [ $? -ne 0 ]; then
        echo "failed write configuration file"
        exit 1
    fi

    install_fedora
    if [ $? -ne 0 ]; then
        echo "failed to install fedora"
        exit 1
    fi

    configure_fedora
    if [ $? -ne 0 ]; then
        echo "failed to configure fedora for a container"
        exit 1
    fi

    type /bin/systemd >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        configure_fedora_init
    else
        configure_fedora_systemd
    fi

    # Enable cgroup
    mkdir $rootfs_path/cgroup
    
    # set up resolv.conf
    cp /etc/resolv.conf $rootfs_path/etc/resolv.conf
    # and /etc/hosts for at least localhost
    [ -f $rootfs_path/etc/hosts ] || echo "127.0.0.1 localhost localhost.localdomain" > $rootfs_path/etc/hosts
    
    # ssh access to lxc
    mkdir $rootfs_path/root/.ssh
    cat /root/.ssh/id_rsa.pub >> $rootfs_path/root/.ssh/authorized_keys
    
    # start container
    lxc-start -d -n $lxc

    lxc-wait -n $lxc -s RUNNING

    echo $IP is up, waiting for ssh...

    ssh_up=""
    for i in $(seq 1 10); do
        echo "ssh attempt $i ..."
        ssh -o "StrictHostKeyChecking no" $IP 'uname -i' && { ssh_up=true; break ; } || :
	sleep 2
    done

    [ -z $ssh_up ] && echo "SSHD in container $lxc is not running"
     

    # rpm --rebuilddb
    chroot $rootfs_path rpm --rebuilddb
    #ssh -o "StrictHostKeyChecking no" $IP "rpm --rebuilddb"

    configure_yum_in_lxc $lxc $fcdistro $pldistro

    return 0
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

    # check for .pkgs file based on pldistro
    if [ -n "$VBUILD_MODE" ] ; then
	pkgsname=devel.pkgs
    else
	pkgsname=vtest.pkgs
    fi
    pkgsfile=$(pl_locateDistroFile $DIRNAME $pldistro $pkgsname)

    ### install individual packages, then groups
    # get target arch - use uname -i here (we want either x86_64 or i386)
   
    lxc_arch=$(chroot $rootfs_path uname -i)
    # on debian systems we get arch through the 'arch' command
    [ "$lxc_arch" = "unknown" ] && lxc_arch=$(chroot $rootfs_path arch)

    packages=$(pl_getPackages -a $lxc_arch $fcdistro $pldistro $pkgsfile)
    groups=$(pl_getGroups -a $lxc_arch $fcdistro $pldistro $pkgsfile)

    case "$pkg_method" in
	yum)
	    [ -n "$packages" ] && chroot $rootfs_path yum -y install $packages
	    for group_plus in $groups; do
		group=$(echo $group_plus | sed -e "s,+++, ,g")
		chroot $rootfs_path yum -y groupinstall "$group"
	    done
	    # store current rpm list in /init-lxc.rpms in case we need to check the contents
	    chroot $rootfs_path rpm -aq > $rootfs_path/init-lxc.rpms
	    ;;
	debootstrap)
	    chroot $rootfs_path apt-get update
	    for package in $packages ; do 
	        chroot $rootfs_path  apt-get install -y $package 
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
    if [ -n "$VBUILD_MODE" ] ; then
	post_install_vbuild "$@" 
    else
	post_install_myplc "$@"
    fi
    # setup localtime from the host
    lxc=$1; shift 
    cp /etc/localtime $rootfs_path/etc/localtime
}

function post_install_vbuild () {

    set -x 
    set -e 
    trap failure ERR INT

    lxc=$1; shift
    personality=$1; shift

### From myplc-devel-native.spec
# be careful to backslash $ in this, otherwise it's the root context that's going to do the evaluation
    cat << EOF | chroot $rootfs_path bash -x
    # set up /dev/loop* in lxc
    for i in \$(seq 0 255) ; do
	mknod -m 640 /dev/loop\$i b 7 \$i
    done
    
    # create symlink for /dev/fd
    [ ! -e "/dev/fd" ] && ln -s /proc/self/fd /dev/fd

    # modify /etc/rpm/macros to not use /sbin/new-kernel-pkg
    sed -i 's,/sbin/new-kernel-pkg:,,' /etc/rpm/macros
    if [ -h "/sbin/new-kernel-pkg" ] ; then
	filename=\$(readlink -f /sbin/new-kernel-pkg)
	if [ "\$filename" == "/sbin/true" ] ; then
		echo "WARNING: /sbin/new-kernel-pkg symlinked to /sbin/true"
		echo "\tmost likely /etc/rpm/macros has /sbin/new-kernel-pkg declared in _netsharedpath."
		echo "\tPlease remove /sbin/new-kernel-pkg from _netsharedpath and reintall mkinitrd."
		exit 1
	fi
    fi
    
    # customize root's prompt
    cat << PROFILE > /root/.profile
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
    cat << EOF | chroot $rootfs_path bash -x

    # create /etc/sysconfig/network if missing
    [ -f /etc/sysconfig/network ] || echo NETWORKING=yes > /etc/sysconfig/network

    # create symlink for /dev/fd
    [ ! -e "/dev/fd" ] && ln -s /proc/self/fd /dev/fd

    # turn off regular crond, as plc invokes plc_crond
    chkconfig crond off

    # take care of loginuid in /etc/pam.d 
    sed -i "s,#*\(.*loginuid.*\),#\1," /etc/pam.d/*

    # customize root's prompt
    cat << PROFILE > /root/.profile
export PS1="[$lxc] \\w # "
PROFILE

EOF
}

function usage () {
    set +x 
    echo "Usage: $COMMAND_VBUILD [options] lxc-name"
    echo "Usage: $COMMAND_MYPLC [options] lxc-name repo-url [ -- lxc-options ]"
    echo "Description:"
    echo "   This command creates a fresh lxc instance, for building, or running, myplc"
    echo "Supported options"
    echo " -f fcdistro - for creating the root filesystem - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -i ifname: determines ip and netmask attached to ifname, and passes it to the lxc"
    echo "-- lxc-options"
    echo "  --netdev : interface to be defined inside lxc"
    echo "  --interface : IP to be defined for the lxc"
    echo "  --hostname : Hostname to be defined for the lxc"
    echo "With $COMMAND_MYPLC you can give 'none' as the URL, in which case"
    echo "   myplc.repo does not get created"
    exit 1
}

### parse args and 
function main () {

    #set -e
    #trap failure ERR INT

    case "$COMMAND" in
	$COMMAND_VBUILD)
	    VBUILD_MODE=true ;;
	$COMMAND_MYPLC)
	    MYPLC_MODE=true;;
	*)
	    usage ;;
    esac

    VERBOSE=
    RESISTANT=""
    IFNAME=""
    LXC_OPTIONS=""
    while getopts "f:d:p:i:" opt ; do
	case $opt in
	    f) fcdistro=$OPTARG;;
	    d) pldistro=$OPTARG;;
	    p) personality=$OPTARG;;
	    i) IFNAME=$OPTARG;;
	    *) usage ;;
	esac
    done
	
    shift $(($OPTIND - 1))

    # parse fixed arguments
    [[ -z "$@" ]] && usage
    lxc=$1 ; shift
    if [ -n "$MYPLC_MODE" ] ; then
	[[ -z "$@" ]] && usage
	REPO_URL=$1 ; shift
    fi

    # parse vserver options
    if [[ -n "$@" ]] ; then
	if [ "$1" == "--" ] ; then
	    shift
	    LXC_OPTIONS="$@"
	else
	    usage
	fi
    fi

    eval set -- "$LXC_OPTIONS"

    while true
     do
        case "$1" in
             --netdev)      IFNAME=$2; shift 2;;
             --interface)   IP=$2; shift 2;;
             --hostname)    HOSTNAME=$2; shift 2;;
             *)             break ;;
        esac
      done

   
    if [ -n "$VBUILD_MODE" ] ; then
	[ -z "$IFNAME" ] && IFNAME=$DEFAULT_IFNAME
        [ -z "$HOSTNAME" ] && HOSTNAME=$lxc
    fi

    [ -z "$fcdistro" ] && fcdistro=$DEFAULT_FCDISTRO
    [ -z "$pldistro" ] && pldistro=$DEFAULT_PLDISTRO
    [ -z "$personality" ] && personality=$DEFAULT_PERSONALITY
    
    release=$(echo $fcdistro | cut -df -f2)

    if [ "$personality" == "linux32" ]; then
        arch=i386
        arch2=x86
    elif [ "$personality" == "linux64" ]; then
        arch=x86_64
        arch2=x86_64
    else
        echo "Unknown personality: $personality"
    fi

    # need lxc installed before we can run lxc-ls
    # need bridge installed
    prepare_host    

    if [ -n "$VBUILD_MODE" ] ; then

	# Bridge IP affectation
	x=$(echo $personality | cut -dx -f2)
	y=$(echo $fcdistro | cut -df -f2)
	z=$(($x + $y))

        IP="192.168.122.$z"
        NETMASK="255.255.255.0"
        GATEWAY="192.168.122.1"
	
        lxc_network_type=veth
        lxc_network_link=virbr0
        echo "the IP address of container $lxc is $IP "
    else
        [[ -z "$REPO_URL" ]] && usage
        [[ -z "$IP" ]] && usage
        NETMASK=$(ifconfig br0 | grep 'inet addr' | awk '{print $4}' | sed -e 's/.*://')
        GATEWAY=$(route -n | grep 'UG' | awk '{print $2}')
        [[ -z "$HOSTNAME" ]] && usage
        lxc_network_type=veth
        lxc_network_link=br0
    fi

    CIDR=$(cidr_notation $NETMASK)
    

    if [ "$(id -u)" != "0" ]; then
          echo "This script should be run as 'root'"
          exit 1
    fi

    path=/var/lib/lxc
    rootfs_path=$path/$lxc/rootfs
    config_path=$path/$lxc
    cache_base=/var/cache/lxc/fedora/$arch
    cache=$cache_base/$release
    root_password=root
    
    # check whether the rootfs directory is created to know if the container exists
    # bacause /var/lib/lxc/$lxc is already created while putting $lxc.timestamp
    [ -d $rootfs_path ] && { echo "container $lxc already exists - exiting" ; exit 1 ; }

    setup_lxc $lxc $fcdistro $pldistro $personality 

    devel_or_vtest_tools $lxc $fcdistro $pldistro $personality

    post_install $lxc $personality
    

    echo $COMMAND Done
}

main "$@"
