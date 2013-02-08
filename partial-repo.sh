#!/bin/sh

COMMAND=$(basename $0)

function usage () {
    echo "Usage: $COMMAND repo1..."
    echo "  a 'RPMS' subdir is expected in each repo arg"
    exit 1
}

[[ -n "$@" ]] || usage
case "$1" in *-h*) usage ;; esac

set -e 

for rpms_dir in $(find "$@" -name RPMS) ; do
    cd $rpms_dir
    cd ..
    echo "==================== Dealing with repo $(pwd)"
    mkdir -p PARTIAL-RPMS
    rsync --archive --verbose $(find RPMS -type f | egrep '/(bootcd|bootstrapfs|nodeimage|noderepo|slicerepo)-.*-.*-.*-.*rpm') PARTIAL-RPMS/
    echo "==================== building packages index in $(pwd) .."
    createrepo PARTIAL-RPMS
    echo '==================== DONE'
    cd - >& /dev/null
done
