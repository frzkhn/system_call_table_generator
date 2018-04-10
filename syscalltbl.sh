#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`

nxt=0;

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "ENTRY(sys_call_table)"

    while read nr abi name entry ; do
	if [ "$nxt" -ne "$nr" ]; then
	    while [ "$nxt" -lt "$nr" ]; do
		echo -e "\t.long sys_ni_syscall"
		let nxt=nxt+1
	    done
	fi
	echo -e "\t.long sys_${name}"
	nxt="$nr"
	let nxt=nxt+1
    done
) > "$out"
