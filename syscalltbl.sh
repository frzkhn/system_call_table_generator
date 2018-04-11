#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`

nxt=0

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#include <asm/unistd.h>"
    echo ""
    echo -e "\t.data"
    echo -e "\t.align 3"
    echo -e "\t.globl sys_call_table"
    echo -e "sys_call_table:"

    while read nr abi name entry ; do
	if [ "$nxt" -ne "$nr" ]; then
	    while [ "$nxt" -lt "$nr" ]; do
		if [ "$nr" -gt 300 ]; then
		    echo -e "\t.quad sys_ni_syscall"
		else 
		    echo -e "\t.quad alpha_ni_syscall"
		fi
		let nxt=nxt+1
	    done
	fi
	echo -e "\t.quad sys_${name}"
	nxt="$nr"
	let nxt=nxt+1
    done

    echo ""
    echo -e "\t.size sys_call_table, . - sys_call_table"
    echo -e "\t.type sys_call_table, @object"
    echo ""
    echo ".ifne (. - sys_call_table) - (NR_SYSCALLS * 8)"
    echo ".err"
    echo ".endif"
) > "$out"
