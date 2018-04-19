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
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo -e "#if !defined(${fileguard}) || defined(__SYSCALL)
#define ${fileguard}

#ifndef __SYSCALL
# define __SYSCALL(nr,func,nargs)
#endif
"
    while read nr abi name entry ; do
	if [ -z "$offset" ]; then
	    if [ "${name}" == "reserved" ] ||
		[ "${name}" == "available" ]; then
		echo -e "#define __NR_${prefix}${name}$nr\t$nr"
		echo -e "__SYSCALL($nr, ${entry}, 0)"
	    else
		echo -e "#define __NR_${prefix}${name}\t$nr"
                echo -e "__SYSCALL($nr, ${entry}, 0)"
	    fi
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
	    echo -e "__SYSCALL($nr, ${entry}, 0)"
        fi
	nxt="$nr"
	let nxt=nxt+1
    done

    echo -e "
#define __NR_syscall_count\t$nxt

#define SYS_XTENSA_RESERVED\t0
#define SYS_XTENSA_ATOMIC_SET\t1
#define SYS_XTENSA_ATOMIC_EXG_ADD\t2
#define SYS_XTENSA_ATOMIC_ADD\t3
#define SYS_XTENSA_ATOMIC_CMP_SWP\t4
#define SYS_XTENSA_COUNT\t5

#undef __SYSCALL
"
    echo "#endif /* ${fileguard} */"
) > "$out"
