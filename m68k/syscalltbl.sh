#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    fileguard=_UAPI_ASM_M68K_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""

	while read nr abi name entry ; do
	    if [ -z "$offset" ]; then
		echo -e "#define __NR_${prefix}${name}\t$nr"
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
            fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo -e "#include <linux/linkage.h>

#ifndef CONFIG_MMU
#define sys_mmap2\tsys_mmap_pgoff
#endif

.section .rodata
ALIGN
ENTRY(sys_call_table)"
	while read nr abi name entry ; do
	    if [ "$nxt" -ne "$nr" ]; then
	        while [ "$nxt" -lt "$nr" ]; do
		    echo -e "\t.long sys_ni_syscall"
		    let nxt=nxt+1
		done
	    fi
	    if [ "${name}" == "fork" ] || 
		[ "${name}" == "vfork" ] || 
		[ "${name}" == "clone" ]; then
		echo -e "\t.long __sys_${name}"
	    else
		echo -e "\t.long sys_${name}"
	    fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
    ) > "$out"
fi
