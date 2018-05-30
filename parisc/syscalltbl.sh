#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

tbl_footer() {
    echo ""
    echo ".ifne (. - 90b) - (__NR_Linux_syscalls * (91b - 90b))"
    echo ".error "\"size of syscall table does not fit value of __NR_Linux_syscalls"\""
    echo ".endif"
}

tbl_out() {
    nxt="$1"
    nr="$2"
    entry="$3"
    dtype="$4"

    if [ $nr -eq 0 ]; then
	echo -e "90:     $dtype $entry"
    elif [ $nr -eq 1 ]; then
	echo -e "91:     $dtype $entry"
    else
	while [ $nxt -lt $nr ]; do
	    echo -e "\t$dtype sys_ni_syscall"
	    let nxt=nxt+1
	done
	echo -e "\t$dtype $entry"
    fi
}

tbl_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 */"    
}

hdr_footer() {
    echo ""
    echo -e "#define __NR_Linux_syscalls\t(__NR_statx + 1)"
    echo ""
    echo -e "#define LINUX_GATEWAY_ADDR\t0x100"
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
}

hdr_fileguard() {
    fileguard=_UAPI_ASM_PARISC_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`_    
}

if [ "${out: -2}" = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	hdr_fileguard
	hdr_header

	while read nr name entry compat comment ; do
	    hdr_out $nr $name
	done

	hdr_footer
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=2
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	tbl_header
	
	while read nr name entry compat comment ; do
	    if [ "$3" = "64" ]; then
		tbl_out $nxt $nr $entry ".dword"
	       	nxt=$nr
		let nxt=nxt+1
	    elif [ "$3" = "32" ]; then
		tbl_out $nxt $nr $entry ".word"
                nxt=$nr
                let nxt=nxt+1
	    elif [ "$3" = "x32" ]; then
		tbl_out $nxt $nr $compat ".dword"
                nxt=$nr
                let nxt=nxt+1
	    fi
	done
	
	tbl_footer
    ) > "$out"
fi
