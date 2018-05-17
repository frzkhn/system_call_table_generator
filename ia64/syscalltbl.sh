#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ "${out: -2}" = ".h" ]; then
    fileguard=_UAPI_ASM_IA64_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
	echo "/*"
	echo " * IA-64 Linux syscall numbers and inline-functions."
	echo " *"
	echo " * Copyright (C) 1998-2005 Hewlett-Packard Co"
	echo " * David Mosberger-Tang <davidm@hpl.hp.com>"
	echo " */"
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo "#include <asm/break.h>"
	echo ""
	echo -e "#define __BREAK_SYSCALL\t__IA64_BREAK_SYSCALL"
	echo ""

	while read nr abi name entry comment ; do
	    if [ -z "$offset" ]; then
		if [ "$name" != "-" ]; then
		    if [ -z "$comment" ]; then
			echo -e "#define __NR_${prefix}${name}\t$nr"
		    else
			echo -e "/* $nr was __NR_${prefix}${name} */"
		    fi
		fi
	    else
		if [ "$name" != "-" ]; then
		    if [ -z "$comment" ]; then
			echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
		    else
			echo -e "/* $nr was __NR_${prefix}${name} */"
		    fi
		fi
            fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=1024
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	echo -e "\t.rodata"
	echo -e "\t.align 8"
	echo -e "\t.globl sys_call_table"
	echo "sys_call_table:"

	while read nr abi name entry comment ; do
	    while [ $nxt -lt $nr ]; do
		if [ $(($nxt % 5)) -eq 0 ]; then
		    echo -e "\tdata8 sys_ni_syscall\t/* $nxt */"
		else
		    echo -e "\tdata8 sys_ni_syscall"
		fi
		let nxt=nxt+1
	    done
	    if [ $(($nxt % 5)) -eq 0 ]; then
		echo -e "\tdata8 ${entry}\t/* $nxt */"
	    else
		echo -e "\tdata8 ${entry}"
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done

	echo ""
	echo -e "\t.org sys_call_table + 8*NR_syscalls\t/* guard against failures to increase NR_syscalls */"
    ) > "$out"
fi
