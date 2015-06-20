#!/bin/sh
# 
# using fedora's mirrormanager (hence report_mirror)
# inspired by
# http://www.techrepublic.com/blog/linux-and-open-source/create-a-local-fedora-mirror-system-and-get-blazing-fast-updates/

current_versions="20 21 22"
upstream_url=rsync://mirror2.hs-esslingen.de/fedora/linux

###
fdest="/mirror/fedora"
# xxx not sure if useful
excludes_file=/mirror/fedora/fedora-excludes.txt

lock=".rsync_updates.lock"
options="$@"

# for safety - clear lock if older than 4 hours
GRACE=240
is_old=$(find $lock -mmin +$GRACE 2> /dev/null)
if [ -n "$is_old" ] ; then
    msg "$lock is older than $GRACE minutes - removing"
    rm -f $lock
fi

if [ -f ${lock} ]; then
    echo "Updates via rsync already running."
    exit 0
fi

for version in $current_versions; do
    if [ ! -d ${fdest}/releases/${version}/Everything ]; then
        echo "Target directory ${fdest}/${releases}/${version}/ not present."
	continue
    fi
    echo "Synchronizing Fedora ${version}"
    pushd ${fdest}/releases/${version} >& /dev/null
    rsync -avH ${upstream_url}/releases/${version}/Everything . --exclude-from=${excludes_file} ${options} \
          --numeric-ids --delete --delete-after --delay-updates
    popd >& /dev/null
    echo "Synchronizing Fedora updates for version ${version}"
    pushd ${fdest}/updates/${version} >& /dev/null
    rsync -avH ${upstream_url}/updates/${version}/ . --exclude-from=${excludes_file} ${options} \
          --numeric-ids --delete --delete-after --delay-updates
    popd >& /dev/null
done

# report to fedora's infra
/usr/bin/report_mirror

#clear lock
/bin/rm -f ${lock}
