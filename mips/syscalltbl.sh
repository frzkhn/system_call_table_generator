#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

tbl_footer() {
    abi="$1"

    if [ "$abi" = "64-o32" ]; then
	echo -e "\t.size\tsys32_call_table,.-sys32_call_table"
    elif [ "$abi" = "64-64" ]; then
	echo -e "\t.size\tsys_call_table,.-sys_call_table"
    elif [ "$abi" = "64-n32" ]; then
	echo -e "\t.size\tsysn32_call_table,.-sysn32_call_table"
    fi
}

tbl_out() {
    nxt="$1"
    nr="$2"
    entry="$3"
    
    while [ $nxt -lt $nr ]; do
        echo -e "\tPTR\tsys_ni_syscall"
        let nxt=nxt+1
    done
    
    echo -e "\tPTR\t$entry"
}

tbl_header() {
    abi="$1"

    echo "/* SPDX-License-Identifier: GPL-2.0 */"
    echo ""
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

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in" | sort -n | (
    tbl_header $abi

    while read nr name entry compat comment ; do
	if [ "$abi" = "64-o32" ]; then
            tbl_out $nxt $nr $compat
	    let nxt=nxt+1
	else
            tbl_out $nxt $nr $entry
            let nxt=nxt+1
	fi
    done
    
    tbl_footer $abi
) > "$out"
