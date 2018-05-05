#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    nxt=0
    fileguard=__ASM_SH_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""
	echo "/*"
	echo " * Copyright (C) 1999  Niibe Yutaka"
	echo " */"
	echo ""
	echo "/*"
	echo " * This file contains the system call numbers."
	echo " */"
	echo ""

	while read nr abi name entry comment ; do
	    if [ -z "$offset" ]; then
		if [ -z "$comment" ]; then
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		else
		    echo -e "\t\t\t$comment"
		fi
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
	echo "/*"
	echo " * arch/sh/kernel/syscalls.S"
	echo " *"
	echo " * System call table for SuperH"
	echo " *"
	echo " *  Copyright (C) 1999, 2000, 2002  Niibe Yutaka"
	echo " *  Copyright (C) 2003  Paul Mundt"
	echo " *"
	echo " * This file is subject to the terms and conditions of the GNU General Public"
	echo " * License.  See the file "\"COPYING"\" in the main directory of this archive"
	echo " * for more details."
	echo " *"
	echo " */"
	echo "#include <linux/sys.h>"
	echo "#include <linux/linkage.h>"
	echo ""
        echo -e "\t.data"
	echo "ENTRY(sys_call_table)"

	while read nr abi name entry comment ; do
	    if [ "$nxt" -ne "$nr" ]; then
		while [ "$nxt" -lt "$nr" ]; do
		    if [ $(($nxt % 5)) -eq 0 ]; then
			echo -e "\t.long sys_ni_syscall\t/* $nxt */"
		    else
			echo -e "\t.long sys_ni_syscall"
		    fi
		    let nxt=nxt+1
		done
	    fi
	    if [ $(($nr % 5)) -eq 0 ]; then
		echo -e "\t.long ${entry}\t/* $nr */"
	    else
		echo -e "\t.long ${entry}"
	    fi
	    nxt="$nr"
	    let nxt=nxt+1
	done
    ) > "$out"
fi
