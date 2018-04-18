#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    fileguard=_UAPI_ASM_PARISC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo -e "#define __NR_Linux\t0"

	while read nr abi name entry ; do
		echo -e "#define __NR_${prefix}${name}\t(__NR_Linux + $nr)"
	done

	echo -e "
#define __NR_Linux_syscalls\t(__NR_statx + 1)

#define __IGNORE_select
#define __IGNORE_fadvise64
#define __IGNORE_pkey_mprotect
#define __IGNORE_pkey_alloc
#define __IGNORE_pkey_free

#define LINUX_GATEWAY_ADDR      0x100
"
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "#if defined(CONFIG_64BIT) && !defined(SYSCALL_TABLE_64BIT)
#define ENTRY_SAME(_name_) .dword sys_##_name_
#define ENTRY_DIFF(_name_) .dword sys32_##_name_
#define ENTRY_UHOH(_name_) .dword sys32_##unimplemented
#define ENTRY_OURS(_name_) .dword parisc_##_name_
#define ENTRY_COMP(_name_) .dword compat_sys_##_name_
#elif defined(CONFIG_64BIT) && defined(SYSCALL_TABLE_64BIT)
#define ENTRY_SAME(_name_) .dword sys_##_name_
#define ENTRY_DIFF(_name_) .dword sys_##_name_
#define ENTRY_UHOH(_name_) .dword sys_##_name_
#define ENTRY_OURS(_name_) .dword sys_##_name_
#define ENTRY_COMP(_name_) .dword sys_##_name_
#else
#define ENTRY_SAME(_name_) .word sys_##_name_
#define ENTRY_DIFF(_name_) .word sys_##_name_
#define ENTRY_UHOH(_name_) .word sys_##_name_
#define ENTRY_OURS(_name_) .word parisc_##_name_
#define ENTRY_COMP(_name_) .word sys_##_name_
#endif
"
	while read nr abi name entry ; do
	    if [ "$nxt" -ne "$nr" ]; then
		while [ "$nxt" -lt "$nr" ]; do
		    echo -e "\tENTRY_SAME(ni_syscall)"
		    let nxt=nxt+1
		done
	    fi
	    echo -e "\t${entry}"
	    nxt="$nr"
	    let nxt=nxt+1
	done

	echo "
.ifne (. - 90b) - (__NR_Linux_syscalls * (91b - 90b))
.error "\"size of syscall table does not fit value of __NR_Linux_syscalls"\"
.endif

#undef ENTRY_SAME
#undef ENTRY_DIFF
#undef ENTRY_UHOH
#undef ENTRY_COMP
#undef ENTRY_OURS
"
    ) > "$out"
fi
