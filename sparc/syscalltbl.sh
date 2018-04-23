#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    nxt=0
    fileguard=_UAPI_SPARC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo "
#ifndef __32bit_syscall_numbers__
#ifndef __arch64__
#define __32bit_syscall_numbers__
#endif
#endif
"
	while read nr abi name entry ; do
	    if [ -z "$offset" ]; then
		if [ "$abi" == 32 ]; then
		    echo "#ifdef __32bit_syscall_numbers__"
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		    echo "#endif"
		elif [ "$abi" == 64 ]; then
		    echo "#ifndef __32bit_syscall_numbers__"
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		    echo "#endif"
		else 
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		fi
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
            fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
	
	echo -e "
#define NR_syscalls\t$nxt
"
	echo -e "
#define KERN_FEATURE_MIXED_MODE_STACK\t0x00000001
"
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	if [ ${out: -4} == "32.S" ]; then
	    echo -e "\t.data"
	    echo -e "\t.align 4"
	    echo -e "\t.globl sys_call_table"
	    echo "sys_call_table:"
	elif [ ${out: -4} == "64.S" ]; then
	    echo -e "\t.text"
	    echo -e "\t.align 4"
	    echo "#ifdef CONFIG_COMPAT"
	    echo -e ".globl sys_call_table32"
	    echo "sys_call_table32:"
	fi

	while read nr abi name entry ; do
	    if [ "$nxt" -ne "$nr" ]; then
		while [ "$nxt" -lt "$nr" ]; do
		    if [ ${out: -4} == "32.S" ]; then
			echo -e "\t.long sys_nis_syscall"
		    elif [ ${out: -4} == "64.S" ]; then
			echo -e "\t.word sys_nis_syscall"
		    fi
		    let nxt=nxt+1
		done
	    fi
	    if [ ${out: -4} == "32.S" ]; then
		echo -e "\t.long ${entry}"
	    elif [ ${out: -4} == "64.S" ]; then
		echo -e "\t.word ${entry}"
	    fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
    ) > "$out"
fi
