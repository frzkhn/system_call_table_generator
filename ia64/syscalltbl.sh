#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

tbl_footer() {
    echo ""
    echo -e "\t.org sys_call_table + 8*NR_syscalls\t/* guard against failures to increase NR_syscalls */"
}

tbl_out() {
    nxt="$1"
    nr="$2"
    entry="$3"

    while [ $nxt -lt $nr ]; do
	echo -e "\tdata8 sys_ni_syscall"
	let nxt=nxt+1
    done

    echo -e "\tdata8 $entry"
}

tbl_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo -e "\t.rodata"
    echo -e "\t.align 8"
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
	echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$const)))"
    fi
}

hdr_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
    echo "/*"
    echo " * IA-64 Linux syscall numbers and inline-functions."
    echo " *"
    echo " * Copyright (C) 1998-2005 Hewlett-Packard Co"
    echo " * David Mosberger-Tang <davidm@hpl.hp.com>"
    echo " */"
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#include <asm/break.h>"
    echo ""
    echo -e "#define __BREAK_SYSCALL\t__IA64_BREAK_SYSCALL"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_ASM_IA64_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
}

if [ "${out: -2}" = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	hdr_fileguard
	hdr_header

	while read nr abi name entry comment ; do
	    hdr_out $nr $name
	done

	hdr_footer
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=1024
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header

	while read nr abi name entry comment ; do
	    tbl_out $nxt $nr $entry
            let nxt=nxt+1
	done

	tbl_footer
    ) > "$out"
fi
