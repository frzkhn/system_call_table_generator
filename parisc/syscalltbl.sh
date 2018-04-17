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
	    if [ "${name}" == "restart_syscall" ]; then
		echo -e "90:\tENTRY_SAME(restart_syscall)"
	    elif [ "${name}" == "exit" ]; then
		echo -e "91:\tENTRY_SAME(exit)"
	    elif [ "${name}" == "fork" ] || 
		[ "${name}" == "vfork" ] ||
		[ "${name}" == "clone" ]; then
		echo -e "\tENTRY_SAME(${name}_wrapper)"
	    elif [ "${name}" == "umount2" ]; then
                echo -e "\tENTRY_SAME(umount)"
	    elif [ "${name}" == "_llseek" ]; then
                echo -e "\tENTRY_SAME(llseek)"
	    elif [ "${name}" == "uname" ]; then
                echo -e "\tENTRY_SAME(new${name})"
	    elif [ "${name}" == "stat" ] ||
		[ "${name}" == "fstat" ] ||
		[ "${name}" == "lstat" ]; then
		echo -e "\tENTRY_COMP(new${name})"
	    elif [ "${name}" == "sgetmask" ] ||
		[ "${name}" == "ssetmask" ]; then
		echo -e "\tENTRY_UHOH(${name})"
	    elif [ "${name}" == "_newselect" ]; then
                echo -e "\tENTRY_COMP(select)"
	    elif [ "${name}" == "_sysctl" ]; then
                echo -e "\tENTRY_COMP(sysctl)"
	    elif [ "${name}" == "pread64" ] ||
		[ "${name}" == "pwrite64" ] ||
		[ "${name}" == "personality" ] ||
		[ "${name}" == "truncate64" ] ||
		[ "${name}" == "ftruncate64" ] ||
		[ "${name}" == "readahead" ] ||
		[ "${name}" == "fadvise64_64" ] ||
		[ "${name}" == "sync_file_range" ] ||
		[ "${name}" == "fallocate" ]; then
		echo -e "\tENTRY_OURS(${name})"
	    elif [ "${name}" == "fanotify_mark" ]; then
                echo -e "\tENTRY_DIFF(${name})"
	    elif [ "${name}" == "open" ] ||
		[ "${name}" == "execve" ] ||
		[ "${name}" == "time" ] ||
		[ "${name}" == "lseek" ] ||
		[ "${name}" == "mount" ] ||
		[ "${name}" == "stime" ] ||
		[ "${name}" == "ptrace" ] ||
		[ "${name}" == "utime" ] ||
		[ "${name}" == "times" ] ||
		[ "${name}" == "ioctl" ] ||
		[ "${name}" == "fcntl" ] ||
		[ "${name}" == "ustat" ] ||
                [ "${name}" == "sigpending" ] ||
                [ "${name}" == "setrlimit" ] ||
                [ "${name}" == "getrlimit" ] ||
                [ "${name}" == "getrusage" ] ||
                [ "${name}" == "gettimeofday" ] ||
                [ "${name}" == "settimeofday" ] ||
                [ "${name}" == "truncate" ] ||
                [ "${name}" == "ftruncate" ] ||
		[ "${name}" == "statfs" ] ||
                [ "${name}" == "fstatfs" ] ||
                [ "${name}" == "setitimer" ] ||
                [ "${name}" == "getitimer" ] ||
                [ "${name}" == "wait4" ] ||
                [ "${name}" == "sysinfo" ] ||
                [ "${name}" == "sendfile" ] ||
                [ "${name}" == "adjtimex" ] ||
                [ "${name}" == "sigprocmask" ] ||
                [ "${name}" == "getdents" ] ||
                [ "${name}" == "select" ] ||
                [ "${name}" == "readv" ] ||
                [ "${name}" == "writev" ] ||
                [ "${name}" == "sysctl" ] ||
                [ "${name}" == "sched_rr_get_interval" ] ||
                [ "${name}" == "nanosleep" ] ||
                [ "${name}" == "sigaltstack" ] ||
                [ "${name}" == "rt_sigaction" ] ||
                [ "${name}" == "rt_sigprocmask" ] ||
                [ "${name}" == "rt_sigpending" ] ||
		[ "${name}" == "rt_sigtimedwait" ] ||
		[ "${name}" == "rt_sigqueueinfo" ] ||
                [ "${name}" == "rt_sigsuspend" ] ||
                [ "${name}" == "setsockopt" ] ||
                [ "${name}" == "getsockopt" ] ||
                [ "${name}" == "sendmsg" ] ||
                [ "${name}" == "recvmsg" ] ||
                [ "${name}" == "semctl" ] ||
                [ "${name}" == "msgsnd" ] ||
                [ "${name}" == "msgrcv" ] ||
                [ "${name}" == "msgctl" ] ||
                [ "${name}" == "shmat" ] ||
                [ "${name}" == "shmctl" ] ||
                [ "${name}" == "fcntl64" ] ||
                [ "${name}" == "sendfile64" ] ||
                [ "${name}" == "futex" ] ||
                [ "${name}" == "sched_setaffinity" ] ||
                [ "${name}" == "sched_getaffinity" ] ||
                [ "${name}" == "io_setup" ] ||
                [ "${name}" == "io_getevents" ] ||
                [ "${name}" == "io_submit" ] ||
		[ "${name}" == "lookup_dcookie" ] ||
                [ "${name}" == "semtimedop" ] ||
                [ "${name}" == "mq_open" ] ||
                [ "${name}" == "mq_timedsend" ] ||
                [ "${name}" == "mq_timedreceive" ] ||
                [ "${name}" == "mq_notify" ] ||
                [ "${name}" == "mq_getsetattr" ] ||
                [ "${name}" == "waitid" ] ||
                [ "${name}" == "timer_create" ] ||
                [ "${name}" == "timer_settime" ] ||
                [ "${name}" == "timer_gettime" ] ||
                [ "${name}" == "clock_settime" ] ||
                [ "${name}" == "clock_gettime" ] ||
                [ "${name}" == "clock_getres" ] ||
                [ "${name}" == "clock_nanosleep" ] ||
                [ "${name}" == "mbind" ] ||
                [ "${name}" == "get_mempolicy" ] ||
                [ "${name}" == "set_mempolicy" ] ||
                [ "${name}" == "keyctl" ] ||
		[ "${name}" == "pselect6" ] ||
                [ "${name}" == "ppoll" ] ||
                [ "${name}" == "openat" ] ||
                [ "${name}" == "futimesat" ] ||
                [ "${name}" == "set_robust_list" ] ||
                [ "${name}" == "get_robust_list" ] ||
                [ "${name}" == "vmsplice" ] ||
                [ "${name}" == "move_pages" ] ||
                [ "${name}" == "epoll_pwait" ] ||
                [ "${name}" == "statfs64" ] ||
                [ "${name}" == "fstatfs64" ] ||
                [ "${name}" == "kexec_load" ] ||
                [ "${name}" == "utimensat" ] ||
                [ "${name}" == "signalfd" ] ||
                [ "${name}" == "timerfd_settime" ] ||
                [ "${name}" == "timerfd_gettime" ] ||
                [ "${name}" == "signalfd4" ] ||
                [ "${name}" == "preadv" ] ||
                [ "${name}" == "pwritev" ] ||
                [ "${name}" == "rt_tgsigqueueinfo" ] ||
		[ "${name}" == "recvmmsg" ] ||
                [ "${name}" == "clock_adjtime" ] ||
                [ "${name}" == "open_by_handle_at" ] ||
                [ "${name}" == "sendmmsg" ] ||
                [ "${name}" == "process_vm_readv" ] ||
                [ "${name}" == "process_vm_writev" ] ||
                [ "${name}" == "utimes" ] ||
                [ "${name}" == "execveat" ] ||
                [ "${name}" == "preadv2" ] ||
                [ "${name}" == "pwritev2" ]; then
		echo -e "\tENTRY_COMP(${name})"
	    else
		echo -e "\tENTRY_SAME(${name})"
	    fi
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
