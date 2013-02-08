#!/bin/sh

COMMAND=$(basename $0)

function usage () {
    echo "Usage: $COMMAND"
    echo "  performs basic checks in all 'PARTIAL-RPMS' found in ."
    exit 1
}

[[ -z "$@" ]] || usage
case "$1" in *-h*) usage ;; esac

set -e 

for partial in $(find . -name 'PARTIAL*'); do
    ls $partial/nodeimage* >& /dev/null \
 || ls $partial/bootstrapfs* >& /dev/null \
 || echo WARNING with $partial - no nodeimage/bootstrapfs
done
