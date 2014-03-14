#!/bin/bash

# taking this bridge-initialization code out of lbuild-initvm.sh 
# so we can use it on our libvirt/lxc local infra 
# there's something very similar in 
# tests/system/template-qemu/qemu-bridge-init
# that the current code was actually based on, but 
# nobody was ever bold enough to reconcile these two 

# hard-wired 
DEFAULT_PUBLIC_BRIDGE=br0

##############################
# use /proc/net/dev instead of a hard-wired list
function gather_interfaces () {
    python <<EOF
for line in file("/proc/net/dev"):
    if ':' not in line: continue
    ifname=line.replace(" ","").split(":")[0]
    if ifname.find("lo")==0: continue
    if ifname.find("br")==0: continue
    if ifname.find("virbr")==0: continue
    if ifname.find("veth")==0: continue
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

##############################
function check_yum_installed () {
    package=$1; shift
    rpm -q $package >& /dev/null || yum -y install $package
}

# not used apparently
function check_yumgroup_installed () {
    group="$1"; shift
    yum grouplist "$group" | grep -q Installed || { yum -y groupinstall "$group" ; }
}

#################### bridge initialization
function create_bridge_if_needed() {

    # do not turn on verbosity
    # set -x

    public_bridge=$1; shift

    # already created ? - we're done
    ip addr show $public_bridge >& /dev/null && {
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
    echo "Creating public bridge interface $public_bridge"
    brctl addbr $public_bridge
    brctl addif $public_bridge $if_lan
    echo "Activating promiscuous mode if_lan=$if_lan"
    ip link set $if_lan up promisc on
    sleep 2
    # rely on dhcp to re assign IP.. 
    echo "Starting dhclient on $public_bridge"
    dhclient $public_bridge
    sleep 1

    #Reconfigure the routing table
    echo "Configuring gateway=$gateway"
    ip route add default via $gateway dev $public_bridge
    ip route del default via $gateway dev $if_lan
    # at this point we have an extra route like e.g.
    ## ip route show
    #default via 138.96.112.250 dev br0
    #138.96.112.0/21 dev em1  proto kernel  scope link  src 138.96.112.57
    #138.96.112.0/21 dev br0  proto kernel  scope link  src 138.96.112.57
    #192.168.122.0/24 dev virbr0  proto kernel  scope link  src 192.168.122.1
    route_dest=$(ip route show | grep -v default | grep "dev $public_bridge" | awk '{print $1;}')
    ip route del $route_dest dev $if_lan

    echo "========== $COMMAND: exiting create_bridge - beg"
    ip addr show
    ip route show
    echo "========== $COMMAND: exiting create_bridge - end"

    # for safety
    sleep 3
    return 0

}

function main () {
    if [[ -n "$@" ]] ; then 
	public_bridge="$1"; shift
    else
	public_bridge="$DEFAULT_PUBLIC_BRIDGE"
    fi
    create_bridge_if_needed $public_bridge
}

main "$@"
