#!/bin/sh
# $URL$

COMMAND=$(basename $0)

function usage () {
    echo "Usage: $COMMAND"
    echo "  performs basic checks in all 'PARTIAL-RPMS' found in ."
    exit 1
}

[[ -n "$@" ]] || usage

set -e 

for partial in $(find . -name 'PARTIAL*'); do
    ls $partial/nodeimage* >& /dev/null \
 || ls $partial/bootstrapfs* >& /dev/null \
 || echo WARNING with $partial
done
