#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

nxt=0

fileguard=_UAPI_ASM_XTENSA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo -e "#if !defined(${fileguard}) || defined(__SYSCALL)
#define ${fileguard}

#ifndef __SYSCALL
# define __SYSCALL(nr,func,nargs)
#endif

#define __NR_spill\t0
__SYSCALL(  0, sys_ni_syscall, 0)
#define __NR_xtensa\t1
__SYSCALL(  1, sys_ni_syscall, 0)
#define __NR_available4\t2
__SYSCALL(  2, sys_ni_syscall, 0)
#define __NR_available5\t3
__SYSCALL(  3, sys_ni_syscall, 0)
#define __NR_available6\t4
__SYSCALL(  4, sys_ni_syscall, 0)
#define __NR_available7\t5
__SYSCALL(  5, sys_ni_syscall, 0)
#define __NR_available8\t6
__SYSCALL(  6, sys_ni_syscall, 0)
#define __NR_available9\t7
__SYSCALL(  7, sys_ni_syscall, 0)"

    while read nr abi name entry ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	    echo -e "__SYSCALL($nr, sys_${name}, nargs)"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
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
