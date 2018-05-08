#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} = ".h" ]; then
    fileguard=_UAPI_ASM_POWERPC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`_
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0+ WITH Linux-syscall-note */"
	echo "/*"
	echo " * This file contains the system call numbers."
	echo " *"
	echo " * This program is free software; you can redistribute it and/or"
	echo " * modify it under the terms of the GNU General Public License"
	echo " * as published by the Free Software Foundation; either version"
	echo " * 2 of the License, or (at your option) any later version."
	echo "*/"
	echo "#ifndef ${fileguard}"
        echo "#define ${fileguard}"
	echo ""

	while read nr name entry_64x32 entry_32 ; do
	    if [ -z "$offset" ]; then
		echo -e "#define __NR_${prefix}${name}\t$nr"
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
	    fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	echo ""
	echo -e "\t.section .rodata,"\"a"\""
	if [ $3 -eq 64x32 ]; then
	    echo -e "\t.p2align\t3"
	fi
	echo -e "\t.globl sys_call_table"
	echo "sys_call_table:"
	
	while read nr name entry_64x32 entry_32 ; do
	    while [ "$nxt" -lt "$nr" ]; do
		if [ $3 -eq 64x32 ]; then
		    echo -e "\t.8byte sys_ni_syscall,sys_ni_syscall"
		elif [ $3 -eq 32 ]; then
		    echo -e "\t.long sys_ni_syscall"
		fi
		let nxt=nxt+1
	    done
	    if [ $3 -eq 64x32 ]; then
		echo -e "\t.8byte ${entry_64x32}"
	    elif [ $3 -eq 32 ]; then
		echo -e "\t.long ${entry_32}"
	    fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
    ) > "$out"
fi
