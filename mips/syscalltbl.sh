#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"

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

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in" | sort -n | (
    nxt=4000
    while read nr name entry compat comment ; do
	if [ "$abi" = "32-o32" -o "$abi" = "64-o32" ]; then
	    let t_nxt=$nxt+0
            emit $t_nxt $nr $entry
	elif [ "$abi" = "64-64" ]; then
	    let t_nxt=$nxt+1000
            emit $t_nxt $nr $entry
	elif [ "$abi" = "64-n32" ]; then
	    let t_nxt=$nxt+2000
            emit $t_nxt $nr $entry
	fi
	nxt=$nr
        let "nxt=nxt+1"
    done
) > "$out"
