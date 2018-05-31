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
    if [ "$abi" = "32" ]; then
	echo -e "\t.data"
        echo -e "\t.align 4"
        echo -e "\t.globl sys_call_table"
        echo "sys_call_table:"
    elif [ "$abi" = "x32" ]; then
        echo -e "\t.text"
        echo -e "\t.align  4"
        echo -e "\t.globl sys_call_table32"
        echo "sys_call_table32:"
    elif [ "$abi" = "64" ]; then
	echo -e "\t.align  4"
	echo -e "\t.globl sys_call_table64, sys_call_table"
	echo "sys_call_table64:"
	echo "sys_call_table:"
    fi
}

hdr_footer() {
    nxt="$1"

    echo ""
    echo -e "#define NR_syscalls\t$nxt"
    echo ""
    echo -e "#define KERN_FEATURE_MIXED_MODE_STACK\t0x00000001"
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
    echo " * System calls under the Sparc."
    echo " *"
    echo " * Don't be scared by the ugly clobbers, it is the only way I can"
    echo " * think of right now to force the arguments into fixed registers"
    echo " * before the trap into the system call with gcc 'asm' statements."
    echo " *"
    echo " * Copyright (C) 1995, 2007 David S. Miller (davem@davemloft.net)"
    echo " *"
    echo " * SunOS compatibility based upon preliminary work which is:"
    echo " *"
    echo " * Copyright (C) 1995 Adrian M. Rodriguez (adrian@remus.rutgers.edu)"
    echo " */"
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#ifndef __32bit_syscall_numbers__"
    echo "#ifndef __arch64__"
    echo "#define __32bit_syscall_numbers__"
    echo "#endif"
    echo "#endif"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_SPARC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
}

if [ "${out: -2}" = ".h" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	hdr_fileguard
	hdr_header

	while read nr name entry_64 entry_32 entry_x32 comment ; do
	    hdr_out $nr $name
	    nxt=$nr
            let nxt=nxt+1
	done

	hdr_footer $nxt
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header $abi
	
            while read nr name entry_64 entry_32 entry_x32 comment ; do
		if [ "$abi" = "64" ]; then
                    tbl_out $nxt $nr $entry_64 ".word"
		    let nxt=nxt+1
		elif [ "$abi" = "32" ]; then
                    tbl_out $nxt $nr $entry_32 ".long"
                    let nxt=nxt+1
		elif [ "$abi" = "x32" ]; then
                    tbl_out $nxt $nr $entry_x32 ".word"
                    let nxt=nxt+1
		fi
	    done
    ) > "$out"
fi
