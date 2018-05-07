#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} = ".h" ]; then
    fileguard=_UAPI_ASM_PARISC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`_
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo "/*"
	echo " * Linux system call numbers."
	echo " *"
	echo " * Cary Coutant says that we should just use another syscall gateway"
	echo " * page to avoid clashing with the HPUX space, and I think he's right:"
	echo " * it will would keep a branch out of our syscall entry path, at the"
	echo " * very least.  If we decide to change it later, we can "\"just"\" tweak"
	echo " * the LINUX_GATEWAY_ADDR define at the bottom and make __NR_Linux be"
	echo " * 1024 or something.  Oh, and recompile libc. =)"
	echo " */"
	echo ""
	echo -e "#define __NR_Linux\t0"

	while read nr name entry_64 entry_32 entry_x32 comment ; do
	    if [ -z "$offset" ]; then
		echo -e "#define __NR_${prefix}${name}\t$nr"
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)\t$comment"
	    fi
	done

	echo ""
	echo -e "#define __NR_Linux_syscalls\t(__NR_statx + 1)"
	echo ""
	echo -e "#define LINUX_GATEWAY_ADDR\t0x100"
	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} = ".S" ]; then
    nxt=2
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	while read nr name entry_64 entry_32 entry_x32 comment ; do
	    if [ $3 -eq 64 ]; then
		if [ $nr -eq 0 ]; then
		    echo -e "90:     .dword ${entry_64}\t/* $nr */"
		elif [ $nr -eq 1 ]; then
		    echo -e "91:     .dword ${entry_64}"
		else
		    while [ "$nxt" -lt "$nr" ]; do
			if [ $(($nxt % 5)) -eq 0 ]; then
			    echo -e "\t.dword sys_ni_syscall\t/* $nxt */"
			else
			    echo -e "\t.dword sys_ni_syscall"
			fi
			let nxt=nxt+1
		    done
		    if [ $(($nr % 5)) -eq 0 ]; then
			echo -e "\t.dword ${entry_64}\t/* $nxt */"
		    else
			echo -e "\t.dword ${entry_64}"
		    fi
		    nxt="$nr"
		    let nxt=nxt+1
		fi
	    elif [ $3 -eq 32 ]; then
		if [ $nr -eq 0 ]; then
		    echo -e "90:     .word ${entry_32}\t/* $nr */"
		elif [ $nr -eq 1 ]; then
		    echo -e "91:     .word ${entry_32}"
		else
		    while [ "$nxt" -lt "$nr" ]; do
			if [ $(($nxt % 5)) -eq 0 ]; then
			    echo -e "\t.word sys_ni_syscall\t/* $nxt */"
			else
			    echo -e "\t.word sys_ni_syscall"
			fi
			let nxt=nxt+1
		    done
		    if [ $(($nr % 5)) -eq 0 ]; then
			echo -e "\t.word ${entry_32}\t/* $nxt */"
		    else
			echo -e "\t.word ${entry_32}"
		    fi
		    nxt="$nr"
		    let nxt=nxt+1
		fi
	    elif [ $3 -eq x32 ]; then
		if [ $nr -eq 0 ]; then
		    echo -e "90:     .dword ${entry_x32}\t/* $nr */"
		elif [ $nr -eq 1 ]; then
		    echo -e "91:     .dword ${entry_x32}"
		else
		    while [ "$nxt" -lt "$nr" ]; do
			if [ $(($nxt % 5)) -eq 0 ]; then
			    echo -e "\t.dword sys_ni_syscall\t/* $nxt */"
			else
			    echo -e "\t.dword sys_ni_syscall"
			fi
			let nxt=nxt+1
		    done
		    if [ $(($nr % 5)) -eq 0 ]; then
			echo -e "\t.dword ${entry_x32}\t/* $nxt */"
		    else
			echo -e "\t.dword ${entry_x32}"
		    fi
		    nxt="$nr"
		    let nxt=nxt+1
		fi
	    fi
	done
	echo ""
	echo ".ifne (. - 90b) - (__NR_Linux_syscalls * (91b - 90b))"
	echo ".error "\"size of syscall table does not fit value of __NR_Linux_syscalls"\""
	echo ".endif"
    ) > "$out"
fi
