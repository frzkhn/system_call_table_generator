#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

fileguard=_UAPI_XTENSA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""

    nxt=0
    while read nr abi name entry comment ; do
	if [ -z "$offset" ]; then
            echo -e "#define __NR_${prefix}${name}\t$nr"
	else
            echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
	fi
	nxt=$nr
	let "nxt=nxt+1"
    done

    echo ""
    echo -e "#define __NR_syscall_count\t$nxt"
    echo ""
    echo "/*"
    echo " * sysxtensa syscall handler"
    echo " *"
    echo " * int sysxtensa (SYS_XTENSA_ATOMIC_SET,     ptr, val,    unused);"
    echo " * int sysxtensa (SYS_XTENSA_ATOMIC_ADD,     ptr, val,    unused);"
    echo " * int sysxtensa (SYS_XTENSA_ATOMIC_EXG_ADD, ptr, val,    unused);"
    echo " * int sysxtensa (SYS_XTENSA_ATOMIC_CMP_SWP, ptr, oldval, newval);"
    echo " *        a2            a6                   a3    a4      a5"
    echo " */"
    echo ""
    echo -e "#define SYS_XTENSA_RESERVED\t0\t/* don't use this */"
    echo -e "#define SYS_XTENSA_ATOMIC_SET\t1\t/* set variable */"
    echo -e "#define SYS_XTENSA_ATOMIC_EXG_ADD\t2\t/* exchange memory and add */"
    echo -e "#define SYS_XTENSA_ATOMIC_ADD\t3\t/* add to memory */"
    echo -e "#define SYS_XTENSA_ATOMIC_CMP_SWP\t4\t/* compare and swap */"
    echo ""
    echo -e "#define SYS_XTENSA_COUNT\t5\t/* count */"
    echo ""
    echo "#endif /* ${fileguard} */"
) > "$out"
