#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`

nxt=0

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    read nr abi name entry
    if [ "${abi}" = 32 ]; then
	echo "#include <linux/sys.h>"
	echo "#include <linux/linkage.h>"
	echo ""
        echo -e "\t.data"
	echo "ENTRY(sys_call_table)"
    else 
	echo "#include <linux/sys.h>"
	echo ""
	echo -e "\t.section .data, \"aw"\"
	echo -e "\t.balign 32"
	echo -e "\t.globl sys_call_table"
	echo "sys_call_table:"
    fi

    if [ "$nxt" -ne "$nr" ]; then
            while [ "$nxt" -lt "$nr" ]; do
                echo -e "\t.long sys_ni_syscall"
                let nxt=nxt+1
            done
    fi
    echo -e "\t.long sys_${name}"
    nxt="$nr"
    let nxt=nxt+1
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
