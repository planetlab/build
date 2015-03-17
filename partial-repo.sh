#!/bin/sh

COMMAND=$(basename $0)

function usage () {
    echo "Usage: $COMMAND repo1..."
    echo "  a 'RPMS' subdir is expected in each repo arg"
    exit 1
}

    OPTS=$(getopt -o "ih" -- "$@")
    if [ $? != 0 ]; then usage; fi
    eval set -- "$OPTS"
    while true; do
	case $1 in
	    -i) INCREMENTAL=true; shift;;
	    -h) usage;;
            --) shift; break ;;
	esac
    done

set -e 

for rpms_dir in $(find "$@" -name RPMS) ; do
    pushd $rpms_dir >& /dev/null
    cd ..
    echo "============================== Dealing with repo $(pwd)"
    if [ -d PARTIAL-RPMS -a -n "$INCREMENTAL" ]; then
	echo "$COMMAND - incremental mode"
	echo "repo $rpms_dir already has a PARTIAL-RPMS - skipped"
	popd >& /dev/null
	continue
    fi
    mkdir -p PARTIAL-RPMS
    echo "========== rsyncing relevant rpms into PARTIAL-RPMS"
    rsync --archive --verbose $(find RPMS -type f | egrep '/(bootcd|bootstrapfs|nodeimage|noderepo|slicerepo)-.*-.*-.*-.*rpm') PARTIAL-RPMS/
    echo "========== building packages index (i.e. running createrepo) in $(pwd)/PARTIAL-RPMS"
    createrepo PARTIAL-RPMS
    echo "========== DONE"
    popd >& /dev/null
done
