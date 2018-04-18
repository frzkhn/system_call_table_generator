#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    fileguard=_UAPI_ASM_IA64_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo "#include <asm/break.h>"
	echo ""
	echo -e "#define __BREAK_SYSCALL\t__IA64_BREAK_SYSCALL"
	echo ""

	while read nr abi name entry ; do
	    if [ -z "$offset" ]; then
		if [ "$name" != "reserved" ]; then
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		fi
	    else
		if [ "$name" != "reserved" ]; then
		    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
		fi
            fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=1024
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
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
	    echo -e "\tdata8 ${entry}"
	    nxt="$nr"
	    let nxt=nxt+1
	done

	echo ""
	echo -e "\t.org sys_call_table + 8*NR_syscalls"
    ) > "$out"
fi
