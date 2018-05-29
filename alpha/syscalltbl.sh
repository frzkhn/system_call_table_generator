#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

t_footer() {
    echo ""
    echo -e "\t.size sys_call_table, . - sys_call_table"
    echo -e "\t.type sys_call_table, @object"
    echo ""
    echo ".ifne (. - sys_call_table) - (NR_SYSCALLS * 8)"
    echo ".err"
    echo ".endif"
}

eprint() {
    nxt="$1"
    t_entry="$2"

    if [ $(($nxt % 5)) -eq 0 ]; then
        echo -e "\t.quad $t_entry\t/* $nxt */"
    else
        echo -e "\t.quad $t_entry"
    fi
}

parse_eprint() {
    nr="$1"
    entry="$2"
    config="$3"

    echo -e "#ifdef $config"
    i_entry="$(cut -d',' -f1 <<< $entry)"
    e_entry="$(cut -d',' -f2 <<< $entry)"
    if [ $(($nr % 5)) -eq 0 ]; then
        echo -e "\t.quad ${i_entry}\t/* $nr */"
        echo "#else"
        echo -e "\t.quad ${e_entry}\t/* $nr */"
    else
        echo -e "\t.quad ${i_entry}"
        echo "#else"
        echo -e "\t.quad ${e_entry}"
    fi
    echo "#endif"
}

chk_ni_syscall() {
    nxt="$1"
    nr="$2"

    while [ $nxt -lt $nr ]; do
	eprint $nxt "alpha_ni_syscall"
        let nxt=nxt+1
    done
}

t_header() {
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

h_footer() {
    echo ""
    echo "#endif /* ${fileguard} */"
}

parse_nprint() {
    nr="$1"
    name="$2"
    comment="$3"    

    if [ -z "$offset" ]; then
	if [ -z "$comment" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t$nr\t$comment"
	fi
    else
	if [ -z "$comment" ]; then
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$const)))"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$const)))\t$comment"
	fi
    fi
}

h_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
}

h_fileguard() {
    fileguard=_UAPI_ALPHA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
}

if [ "${out: -2}" = ".h" ]; then
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	h_fileguard
	h_header
	while read nr abi name entry config comment ; do
	    parse_nprint $nr $name "$comment"
	done
	h_footer
    ) > "$out"
elif [ "${out: -2}" = ".S" ]; then
    nxt=0
    grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
	t_header
	while read nr abi name entry config comment ; do
	    chk_ni_syscall $nxt $nr
	    if [ -z "$config" -o "$config" = "-" ]; then
		eprint $nr $entry
	    else
		parse_eprint $nr $entry $config
	    fi
            let nxt=nxt+1
	done
	t_footer
    ) > "$out"
fi
