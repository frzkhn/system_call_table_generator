#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

emit() {
    nxt="$1"
    nr="$2"
    entry="$3"
    
    while [ $nxt -lt $nr ]; do
	echo "__SYSCALL($nxt, sys_ni_syscall, )"
        let "nxt=nxt+1"
    done
    
    echo "__SYSCALL($nr, $entry, )"
}

grep '^[0-9]' "$in" | sort -n | (
    while read nr name entry_64 entry_32 entry_x32 comment ; do
	if [ "$abi" = "64" ]; then
            emit $nxt $nr $entry_64
	elif [ "$abi" = "32" ]; then
            emit $nxt $nr $entry_32
	elif [ "$abi" = "x32" ]; then
            emit $nxt $nr $entry_x32
	fi
	nxt=$nr
        let "nxt=nxt+1"
    done
) > "$out"
