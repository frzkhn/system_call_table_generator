#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`

nxt=1024

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo ""
    echo -e "\t.rodata"
    echo -e "\t.align 8"
    echo -e "\t.globl sys_call_table"
    echo "sys_call_table:"

    while read nr abi name entry ; do
	if [ "$nxt" -ne "$nr" ]; then
	            while [ "$nxt" -lt "$nr" ]; do
			    echo -e "\tdata8 sys_ni_syscall"
			        let nxt=nxt+1
				done
		    fi
	echo -e "\tdata8 sys_${name}"
	nxt="$nr"
	let nxt=nxt+1
    done

    echo ""
    echo -e "\t.org sys_call_table + 8*NR_syscalls"
) > "$out"
