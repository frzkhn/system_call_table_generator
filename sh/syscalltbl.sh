#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    nxt=0
    fileguard=_UAPI_ASM_SH_`basename "$out" | sed \
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
	    nxt="$nr"
	    let nxt=nxt+1
	done
	
	echo ""
	echo -e "#define NR_syscalls\t$nxt"

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	read nr abi name entry
	if [ "$abi" == "32" ]; then
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
	    if [ "${name}" == "mmap" ]; then
		echo -e "\t.long old_${name}"
	    elif [ "${name}" == "ptrace" ] && 
		[ "$abi" == "64" ]; then
                echo -e "\t.long sh64_${name}"
            else
		 echo -e "\t.long ${entry}"
            fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
    ) > "$out"
fi
