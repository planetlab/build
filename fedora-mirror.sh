#!/bin/bash
# this can help you create/update your fedora mirror

COMMAND=$(basename $0)
LOGDIR=/var/log/fedora-mirror
DATE=$(date '+%Y-%m-%d-%H-%M')
LOG=${LOGDIR}/${DATE}.log

dry_run=
verbose=--verbose
log=
skip_core=true
root=/mirror/


us_fedora_url=rsync://mirrors.kernel.org/fedora
eu_fedora_url=rsync://mirror1.hs-esslingen.de/fedora/linux

default_distroname="f22"
all_distronames="f20 f21 f22"

global_arch="x86_64"

# use EU mirror
fedora_url=$eu_fedora_url

function mirror_distro_arch () {
    distroname=$1; shift
    arch=$1; shift

    distroname=$(echo $distroname | tr '[A-Z]' '[a-z]')
    case $distroname in
	f*)
	    distroindex=$(echo $distroname | sed -e "s,f,,g")
	    distro="Fedora"
	    rsyncurl=$fedora_url
	    ;;
	*)
	    echo "WARNING -- Unknown distribution $distroname -- skipped"
	    return 1
	    ;;
    esac

    excludelist="debug/ iso/ ppc/ source/"
    options=""
    [ -n "$(rsync --help | grep no-motd)" ] && options="$options --no-motd"
    options="$options $dry_run $verbose"
    options="$options -aH --numeric-ids"
    options="$options --delete --delete-excluded --delete-after --delay-updates"
    for e in $excludelist; do
	options="$options --exclude $e"
    done

    echo ">>>>>>>>>>>>>>>>>>>> distroname=$distroname arch=$arch rsyncurl=$rsyncurl"
    [ -n "$verbose" ] && echo "rsync options=$options"

    paths=""
    [ -z "$skip_core" ] && paths="releases/$distroindex/Everything/$arch/os/"
    paths="$paths updates/$distroindex/$arch/"
    localpath=fedora

    for repopath in $paths; do
	echo "===== $distro -> $distroindex $repopath"
	[ -z "$dry_run" ] && mkdir -p ${root}/${localpath}/${repopath}
	command="rsync $options ${rsyncurl}/${repopath} ${root}/${localpath}/${repopath}"
	echo $command
	$command
    done

    echo "<<<<<<<<<<<<<<<<<<<< $distroname $arch"

    return $RES 
}

function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-l] [-c] [-e|-s|-u rsyncurl] [-f distroname|-F]"
    echo "Options:"
    echo " -n : dry run"
    echo " -v : turn off verbose"
    echo " -l : turns on autologging in $LOGDIR"
    echo " -c : also sync core repository (releases)"
    echo " -s : uses US mirror $us_fedora_url"
    echo " -e : uses EU mirror $eu_fedora_url"
    echo " -u <url> : use this (rsync) for fedora (default is $fedora_url)"
    echo " -f distroname - default is $default_distroname"
    echo " -F : do on all distros $all_distronames"
    exit 1
}

function run () {
    RES=0
    for distroname in $distronames ; do 
	for arch in $archs; do 
	    mirror_distro_arch "$distroname" "$arch" || RES=1
	done
    done
    return $RES
}

function main () {
    distronames=""
    archs="$global_arch"
    while getopts "nvlc:u:sef:Fh" opt ; do
	case $opt in
	    n) dry_run=--dry-run ;;
	    v) verbose= ;;
	    l) log=true ;;
	    c) skip_core= ;;
	    u) fedora_url=$OPTARG ;;
	    s) fedora_url=$us_fedora_url ;;
	    e) fedora_url=$eu_fedora_url ;;
	    f) distronames="$distronames $OPTARG" ;;
	    F) distronames="$distronames $all_distronames" ;;
	    h|*) usage ;;
	esac
    done
    shift $(($OPTIND-1))
    [[ -n "$@" ]] && usage
    [ -z "$distronames" ] && distronames=$default_distroname

    # auto log : if specified
    if [ -n "$log" ] ; then
	mkdir -p $LOGDIR
	run &> $LOG
    else
	run
    fi 
    if [ "$?" == 0 ]; then
	# report to fedora's infra
	# can't get the config right...
	#/usr/bin/report_mirror
	exit 0
    else
	exit 1
    fi
}

main "$@"
