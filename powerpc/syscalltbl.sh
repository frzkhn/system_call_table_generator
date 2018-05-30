#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

tbl_out() {
    nxt="$1"
    nr="$2"
    entry="$3"
    dtype="$4"
    
    while [ $nxt -lt $nr ]; do
        echo -e "\t$dtype sys_ni_syscall"
        let nxt=nxt+1
    done
    
    echo -e "\t$dtype $entry"
}

tbl_header() {
    abi="$1"

    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo ""
    echo -e "\t.section .rodata,"\"a"\""
    if [ "$abi" = "64" -o "$abi" = "x32" ]; then
	echo -e "\t.p2align\t3"
    fi
    echo -e "\t.globl sys_call_table"
    echo "sys_call_table:"
}

hdr_footer() {
    echo ""
    echo "#endif /* ${fileguard} */"
}

hdr_out() {
    nr="$1"
    name="$2"

    if [ -z "$offset" ]; then
	echo -e "#define __NR_${prefix}${name}\t$nr"
    else
	echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
    fi
}

hdr_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0+ WITH Linux-syscall-note */"
    echo "/*"
    echo " * This file contains the system call numbers."
    echo " *"
    echo " * This program is free software; you can redistribute it and/or"
    echo " * modify it under the terms of the GNU General Public License"
    echo " * as published by the Free Software Foundation; either version"
    echo " * 2 of the License, or (at your option) any later version."
    echo " */"
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_ASM_POWERPC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`_
}

if [ "${out: -2}" = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	hdr_fileguard
	hdr_header

	while read nr name entry_64 entry_x32 entry_32 config ; do
	    hdr_out $nr $name
	done

	hdr_footer
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header $abi

	while read nr name entry_64 entry_x32 entry_32 config ; do
	    if [ "$abi" = "64" ]; then
                tbl_out $nxt $nr $entry_64 ".8byte"
		let nxt=nxt+1
            elif [ "$abi" = "32" ]; then
                tbl_out $nxt $nr $entry_32 ".long"
                let nxt=nxt+1
            elif [ "$abi" = "x32" ]; then
                tbl_out $nxt $nr $entry_x32 ".8byte"
                let nxt=nxt+1
            fi
	done
    ) > "$out"
fi
