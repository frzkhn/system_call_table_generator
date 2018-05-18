#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

if [ "${out: -2}" = ".h" ]; then
    fileguard=_UAPI_ASM_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
	echo "/*"
	echo " * This file is subject to the terms and conditions of the GNU General Public"
	echo " * License.  See the file "\"COPYING"\" in the main directory of this archive"
	echo " * for more details."
	echo " *"
	echo " * Copyright (C) 1995, 96, 97, 98, 99, 2000 by Ralf Baechle"
	echo " * Copyright (C) 1999, 2000 Silicon Graphics, Inc."
	echo " *"
	echo " * Changed system calls macros _syscall5 - _syscall7 to push args 5 to 7 onto"
	echo " * the stack. Robin Farine for ACN S.A, Copyright (C) 1996 by ACN S.A"
	echo " */"
	echo "#ifndef ${fileguard}"
        echo "#define ${fileguard}"
        echo ""
	echo "#include <asm/sgidefs.h>"
	echo ""
	if [ "$abi" = "32_o32" ]; then
	    echo "#if _MIPS_SIM == _MIPS_SIM_ABI32"
	    echo ""
	    echo "/*"
	    echo " * Linux o32 style syscalls are in the range from 4000 to 4999."
	    echo " */"
	    echo -e "#define __NR_Linux\t4000"
	fi
	
	while read nr name entry compat comment ; do
	    if [ -z "$offset" ]; then
		if [ -z "$comment" ]; then
		    echo -e "#define __NR_${prefix}${name}\t$nr"
		else
		    echo -e "/* #define __NR_${prefix}${name}\t$nr */"
		fi
	    else
		if [ -z "$comment" ]; then
		    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-4000)))"
		else
		    echo -e "/* #define __NR_${prefix}${name}\t($offset + $(($nr-4000))) */"
		fi
	    fi
	done
	
	if [ "$abi" = "32_o32" ]; then
	    echo ""
	    echo "/*"
	    echo " * Offset of the last Linux o32 flavoured syscall"
	    echo " */"
	    echo -e "#define __NR_Linux_syscalls\t366"
	    echo ""
	    echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI32 */"
	fi
	echo ""
	echo "#endif /* ${fileguard} */"
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	echo "/* SPDX-License-Identifier: GPL-2.0 */"
	echo ""
	if [ "$abi" = "32_o32" ]; then
	    nxt=4000
	    echo -e "\t.align\t2"
	    echo -e "\t.type\tsys_call_table, @object"
	    echo "EXPORT(sys_call_table)"
	elif [ "$abi" = "64_o32" ]; then
	    nxt=4000
            echo -e "\t.align\t3"
            echo -e "\t.type\tsys32_call_table,@object"
            echo "EXPORT(sys32_call_table)"
	elif [ "$abi" = "64_64" ]; then
	    nxt=5000
	    echo -e "\t.align\t3"
            echo -e "\t.type\tsys_call_table, @object"
            echo "EXPORT(sys_call_table)"
	elif [ "$abi" = "64_n32" ]; then
	    nxt=6000
            echo -e "\t.type\tsysn32_call_table, @object"
            echo "EXPORT(sysn32_call_table)"
	fi

	while read nr name entry compat comment ; do
	    while [ $nxt -lt $nr ]; do
		if [ $(($nxt % 5)) -eq 0 ]; then
		    echo -e "\tPTR\tsys_ni_syscall\t/* $nxt */"
		else
		    echo -e "\tPTR\tsys_ni_syscall"
		fi
		let nxt=nxt+1
	    done

	    if [ "$abi" = "64_o32" ]; then
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\tPTR\t${compat}\t/* $nxt */"
                else
		    echo -e "\tPTR\t${compat}"
                fi
	    else
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\tPTR\t${entry}\t/* $nxt */"
		else
		    echo -e "\tPTR\t${entry}"
		fi
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done

	if [ "$abi" = "64_o32" ]; then
	    echo -e "\t.size\tsys32_call_table,.-sys32_call_table"
	elif [ "$abi" = "64_64" ]; then
	    echo -e "\t.size\tsys_call_table,.-sys_call_table"
	elif [ "$abi" = "64_n32" ]; then
	    echo -e "\t.size\tsysn32_call_table,.-sysn32_call_table"
	fi
    ) > "$out"
fi
