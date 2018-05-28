#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

eprint() {
    nr="$1"
    entry="$2"
    
    if [ $(($nr % 5)) -eq 0 ]; then
        echo -e "\tPTR\t$entry\t/* $nxt */"
    else
        echo -e "\tPTR\t$entry"
    fi
}

parse_config_eprint() {
    nr="$1"
    entry="$2"
    config="$3"

    e_config="$(cut -d',' -f1 <<< $config)"
    n_config="$(cut -d',' -f2 <<< $config)"
    if [ "$e_config" != "-" ]; then
	echo "#ifdef $e_config"
    elif [ "$n_config" != "-" ]; then
	echo "#ifndef $n_config"
    fi
    i_entry="$(cut -d',' -f1 <<< $entry)"
    e_entry="$(cut -d',' -f2 <<< $entry)"
    if [ "$i_entry" != "-" ]; then
	eprint $nr $i_entry
    fi
    if [ "$e_entry" != "-" ]; then
	echo "#else"
	eprint $nr $e_entry
    fi
    echo "#endif"
}

chk_ni_syscall() {
    nxt="$1"
    nr="$2"

    while [ $nxt -lt $nr ]; do
	eprint $nxt "sys_ni_syscall"
        let nxt=nxt+1
    done
}

footer() {
    abi="$1"

    if [ "$abi" = "64-o32" ]; then
	echo -e "\t.size\tsys32_call_table,.-sys32_call_table"
    elif [ "$abi" = "64-64" ]; then
	echo -e "\t.size\tsys_call_table,.-sys_call_table"
    elif [ "$abi" = "64-n32" ]; then
	echo -e "\t.size\tsysn32_call_table,.-sysn32_call_table"
    fi
}

header() {
    abi="$1"

    if [ "$abi" = "32-o32" ]; then
	nxt=4000
	echo -e "\t.align\t2"
	echo -e "\t.type\tsys_call_table, @object"
	echo "EXPORT(sys_call_table)"
    elif [ "$abi" = "64-o32" ]; then
	nxt=4000
        echo -e "\t.align\t3"
        echo -e "\t.type\tsys32_call_table,@object"
        echo "EXPORT(sys32_call_table)"
    elif [ "$abi" = "64-64" ]; then
	nxt=5000
	echo -e "\t.align\t3"
        echo -e "\t.type\tsys_call_table, @object"
        echo "EXPORT(sys_call_table)"
    elif [ "$abi" = "64-n32" ]; then
	nxt=6000
        echo -e "\t.type\tsysn32_call_table, @object"
        echo "EXPORT(sysn32_call_table)"
    fi
}

license() {
    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo ""
}

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in" | sort -n | (
    license
    header $abi
    if [ "$abi" = "32-o32" ]; then
	while read nr name entry compat config comment ; do
	    chk_ni_syscall $nxt $nr
	    
	    if [ -z "$config" -o "$config" = "-" ]; then
		eprint $nr $entry
	    else
		parse_config_eprint $nr $entry $config
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done
    else
	while read nr name entry compat comment ; do
	    chk_ni_syscall $nxt $nr

	    if [ "$abi" = "64-o32" ]; then
		eprint $nr $compat
	    else
		eprint $nr $entry
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done
    fi
    footer $abi
) > "$out"
