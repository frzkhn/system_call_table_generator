#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

tbl_out() {
    nxt="$1"
    nr="$2"
    entry="$3"

    while [ $nxt -lt $nr ]; do
	echo -e "\t.long sys_ni_syscall"
	let nxt=nxt+1
    done

    echo -e "\t.long $entry"
}

tbl_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo "ENTRY(sys_call_table)"
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
    echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
    echo "/*"
    echo " * Copyright (C) 2007-2008 Michal Simek <monstr@monstr.eu>"
    echo " * Copyright (C) 2006 Atmark Techno, Inc."
    echo " *"
    echo " * This file is subject to the terms and conditions of the GNU General Public"
    echo " * License. See the file "\"COPYING"\" in the main directory of this archive"
    echo " * for more details."
    echo " */"
    echo ""
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_ASM_MICROBLAZE_`basename "$out" | sed \
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
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header

	while read nr abi name entry comment ; do
	    tbl_out $nxt $nr $entry
            let nxt=nxt+1
	done
    ) > "$out"
fi
