#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

tbl_footer() {
    echo ""
    echo -e "\t.size sys_call_table, . - sys_call_table"
    echo -e "\t.type sys_call_table, @object"
    echo ""
    echo ".ifne (. - sys_call_table) - (NR_SYSCALLS * 8)"
    echo ".err"
    echo ".endif"
}

check_ni_syscall() {
    nxt="$1"
    nr="$2"

    while [ $nxt -lt $nr ]; do
	echo -e "\t.quad alpha_ni_syscall"
        let nxt=nxt+1
    done
}

tbl_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo "/*"
    echo " * arch/alpha/kernel/systbls.S"
    echo " *"
    echo " * The system call table."
    echo " */"
    echo ""
    echo "#include <asm/unistd.h>"
    echo ""
    echo -e "\t.data"
    echo -e "\t.align 3"
    echo -e "\t.globl sys_call_table"
    echo -e "sys_call_table:"
}

hdr_footer() {
    echo ""
    echo "#endif /* ${fileguard} */"
}

parse_header() {
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
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_ALPHA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
}

if [ "${out: -2}" = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	hdr_fileguard
	hdr_header
	while read nr abi name entry config comment ; do
	    parse_header $nr $name
	done
	hdr_footer
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header
	while read nr abi name entry config comment ; do
	    check_ni_syscall $nxt $nr
	    echo -e "\t.quad $entry"
            let nxt=nxt+1
	done
	tbl_footer
    ) > "$out"
fi
