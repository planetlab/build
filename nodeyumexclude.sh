#!/bin/bash

COMMAND=$(basename $0)
. $(dirname $0)/build.common

function usage () {
    echo "Usage: $COMMAND fcdistro pldistro"
    echo "outputs the list of packages to exclude from the stock repo"
    echo "this is set in yumexclude.pkgs, and needs to match the set of packages"
    echo "that are produced by the planetlab build and meant to replace the stock ones"
    exit 1
}

[[ -z "$@" ]] && usage
FCDISTRO=$1; shift
[[ -z "$@" ]] && usage
PLDISTRO=$1; shift
[[ -n "$@" ]] && usage

pl_nodeyumexclude "$FCDISTRO" "$PLDISTRO"
