#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

fileguard=_UAPI_SPARC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#ifndef __32bit_syscall_numbers__"
    echo "#ifndef __arch64__"
    echo "#define __32bit_syscall_numbers__"
    echo "#endif"
    echo "#endif"
    echo ""

    nxt=0
    while read nr name entry_64 entry_32 entry_x32 comment ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
	fi
	nxt=$nr
        let "nxt=nxt+1"
    done

    echo ""
    echo -e "#define NR_syscalls\t$nxt"
    echo ""
    echo -e "#define KERN_FEATURE_MIXED_MODE_STACK\t0x00000001"
    echo ""
    echo "#endif /* ${fileguard} */"
) > "$out"
