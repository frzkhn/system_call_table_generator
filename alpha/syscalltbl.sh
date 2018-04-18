#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    fileguard=_UAPI_ASM_ALPHA_`basename "$out" | sed \
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

	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
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
		    echo -e "\t.quad alpha_ni_syscall"
		    let nxt=nxt+1
		done
	    fi
            echo -e "\t.quad ${entry}"
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
fi
