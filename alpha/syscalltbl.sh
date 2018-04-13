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
	    if [ "$nr" -eq 300 ]; then
		echo "
#define __IGNORE_alarm
#define __IGNORE_creat
#define __IGNORE_getegid
#define __IGNORE_geteuid
#define __IGNORE_getgid
#define __IGNORE_getpid
#define __IGNORE_getppid
#define __IGNORE_getuid
#define __IGNORE_pause
#define __IGNORE_time
#define __IGNORE_utime
#define __IGNORE_umount2
"
	    fi

	    if [ -z "$offset" ]; then
		echo -e "#define __NR_${prefix}${name}\t$nr"
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
            fi
	done

	echo "
#define __IGNORE_pkey_mprotect
#define __IGNORE_pkey_alloc
#define __IGNORE_pkey_free
"
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
		    if [ "$nr" -gt 300 ]; then
			echo -e "\t.quad sys_ni_syscall"
		    else 
			echo -e "\t.quad alpha_ni_syscall"
		    fi
		    let nxt=nxt+1
		done
	    fi
	    if [ "${name}" == "fork" ] ||
		 [ "${name}" == "vfork" ] || 
		 [ "${name}" == "clone" ]; then
                echo -e "\t.quad alpha_${name}"
            else
                echo -e "\t.quad sys_${name}"
            fi
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
