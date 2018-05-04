#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

if [ ${out: -2} == ".h" ]; then
    fileguard=_UAPI_ASM_MICROBLAZE_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
	echo "/*"
	echo " * Copyright (C) 2007-2008 Michal Simek <monstr@monstr.eu>"
	echo " * Copyright (C) 2006 Atmark Techno, Inc."
	echo " *"
	echo " * This file is subject to the terms and conditions of the GNU General Public"
	echo " * License. See the file "COPYING" in the main directory of this archive"
	echo " * for more details."
	echo " */"
	echo ""
	echo "#ifndef ${fileguard}"
	echo "#define ${fileguard}"
	echo ""

	while read nr abi name entry comment ; do
	    if [ -z "$offset" ]; then
		if [ -z "$comment" ]; then
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		else
		    echo -e "#define __NR_${prefix}${name}\t$nr\t$comment"
		fi
	    else
		echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
            fi
	done

	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ ${out: -2} == ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
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
