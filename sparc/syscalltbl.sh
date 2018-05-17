#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

if [ "${out: -2}" = ".h" ]; then
    nxt=0
    fileguard=_UAPI_SPARC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo "#ifndef __32bit_syscall_numbers__"
	echo "#ifndef __arch64__"
	echo "#define __32bit_syscall_numbers__"
	echo "#endif"
	echo "#endif"
	echo ""

	while read nr name entry_64 entry_32 entry_x32 ; do
	    if [ -z "$offset" ]; then
		if [ "$entry_32" != "sys_nis_syscall" -a "$entry_64" == "sys_nis_syscall" ]; then
		    echo "#ifdef __32bit_syscall_numbers__"
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		    echo "#endif"
		elif [ "$entry_32" == "sys_nis_syscall" -a "$entry_64" != "sys_nis_syscall" ]; then
		    echo "#ifndef __32bit_syscall_numbers__"
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		    echo "#endif"
		else 
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		fi
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
            fi
	    nxt=$nr
	    let nxt=nxt+1
	done
	
	echo ""
	echo -e "#define NR_syscalls\t$nxt"
	echo ""
	echo -e "#define KERN_FEATURE_MIXED_MODE_STACK\t0x00000001"
	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    arr_entry64=()
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	if [ "$abi" = "32" ]; then
	    echo -e "\t.data"
            echo -e "\t.align 4"
            echo -e "\t.globl sys_call_table"
            echo "sys_call_table:"
            while read nr name entry_64 entry_32 entry_x32 ; do
                while [ $nxt -lt $nr ]; do
		    if [ $(($nxt % 5)) -eq 0 ]; then
			echo -e "\t.long sys_nis_syscall\t/* $nxt */"
		    else
			echo -e "\t.long sys_nis_syscall"
		    fi
		    let nxt=nxt+1
                done
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\t.long ${entry_32}\t/* $nxt */"
		else
		    echo -e "\t.long ${entry_32}"
		fi
		nxt=$nr
		let nxt=nxt+1
            done
	elif [ "$abi" = "64" ]; then
            echo -e "\t.text"
            echo -e "\t.align  4"
            echo "#ifdef CONFIG_COMPAT"
            echo -e "\t.globl sys_call_table32"
            echo "sys_call_table32:"
            while read nr name entry_64 entry_32 entry_x32 ; do
                while [ $nxt -lt $nr ]; do
		    if [ $(($nxt % 5)) -eq 0 ]; then
			echo -e "\t.word sys_nis_syscall\t/* $nxt */"
		    else
			echo -e "\t.word sys_nis_syscall"
		    fi
                    arr_entry64+=("sys_nis_syscall")
		    let nxt=nxt+1
                done
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\t.word ${entry_x32}\t/* $nxt */"
		else
                    echo -e "\t.word ${entry_x32}"
		fi
                nxt=$nr
		arr_entry64+=("${entry_64}")
                let nxt=nxt+1
            done
            echo "#endif /* CONFIG_COMPAT */"
	    echo ""
	    echo -e "\t.align  4"
	    echo -e "\t.globl sys_call_table64, sys_call_table"
	    echo "sys_call_table64:"
	    echo "sys_call_table:"
	    nr_max=$nxt
	    nxt=0
	    while [ $nxt -lt $nr_max ]; do
		if [ $(($nxt % 5)) -eq 0 ]; then
		    echo -e "\t.word ${arr_entry64[nxt]}\t/* $nxt */"
		else
		    echo -e "\t.word ${arr_entry64[nxt]}"
		fi
		let nxt=nxt+1
	    done
	fi
    ) > "$out"
fi
