#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

nxt=0

fileguard=_UAPI_XTENSA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
if [ ${out: -2} = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
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
	echo -e "#define __NR_syscall_count\t$nxt"
	echo ""
	echo -e "#define SYS_XTENSA_RESERVED\t0"
	echo -e "#define SYS_XTENSA_ATOMIC_SET\t1"
	echo -e "#define SYS_XTENSA_ATOMIC_EXG_ADD\t2"
	echo -e "#define SYS_XTENSA_ATOMIC_ADD\t3"
	echo -e "#define SYS_XTENSA_ATOMIC_CMP_SWP\t4"
	echo -e "#define SYS_XTENSA_COUNT\t5"
	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} = ".c" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	echo ""
	echo "#include <linux/linkage.h>"
	echo "#include <linux/syscalls.h>"
	echo "#include <uapi/asm/unistd.h>"
	echo ""
	echo "typedef void (*syscall_t)(void);"
	echo ""
	echo "syscall_t sys_call_table[__NR_syscall_count] = {"
	echo "  [0 ... __NR_syscall_count - 1] = (syscall_t)&sys_ni_syscall," 
	echo ""

	while read nr abi name entry comment ; do
	    if [ "$nxt" -ne "$nr" ]; then
		while [ "$nxt" -lt "$nr" ]; do
		    echo -e "  [ "$nxt" ] = (syscall_t)sys_ni_syscall,"
		    let nxt=nxt+1
		done
	    fi
	    echo -e "  [ "$nxt" ] = (syscall_t)${entry},"
	    nxt="$nr"
	    let nxt=nxt+1
	done
	echo "};"
    ) > "$out"
fi
