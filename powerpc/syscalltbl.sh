#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

if [ "${out: -2}" = ".h" ]; then
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
	echo " */"
	echo "#ifndef ${fileguard}"
        echo "#define ${fileguard}"
	echo ""

	while read nr name entry_64x32 entry_32 config ; do
	    if [ -z "$offset" ]; then
		if [ -z "$config" ]; then
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		else
		    e_config="$(cut -d',' -f1 <<< $config)"
                    n_config="$(cut -d',' -f2 <<< $config)"
		    if [ "$e_config" != "-" ]; then
			echo "#ifdef $e_config"
		    elif [ "$n_config" != "-" ]; then
			echo "#ifndef $n_config"
		    fi
		    i_name="$(cut -d',' -f1 <<< $name)"
		    e_name="$(cut -d',' -f2 <<< $name)"
		    if [ "$i_name" != "-" ]; then
			echo -e "#define __NR_${prefix}${i_name}\t$nr"
		    fi
		    if [ "$e_name" != "-" ]; then
			echo "#else"
			echo -e "#define __NR_${prefix}${e_name}\t$nr"
		    fi
		    echo "#endif"
		fi
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
	    fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	echo ""
	echo -e "\t.section .rodata,"\"a"\""
	if [ "$abi" = "64x32" ]; then
	    echo -e "\t.p2align\t3"
	fi
	echo -e "\t.globl sys_call_table"
	echo "sys_call_table:"
	
	while read nr name entry_64x32 entry_32 config ; do
	    while [ $nxt -lt $nr ]; do
		if [ "$abi" = "64x32" ]; then
		    echo -e "\t.8byte sys_ni_syscall,sys_ni_syscall"
		elif [ "$abi" = "32" ]; then
		    echo -e "\t.long sys_ni_syscall"
		fi
		let nxt=nxt+1
	    done
	    if [ "$abi" = "64x32" ]; then
		echo -e "\t.8byte ${entry_64x32}"
	    elif [ "$abi" = "32" ]; then
		echo -e "\t.long ${entry_32}"
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done
    ) > "$out"
fi
