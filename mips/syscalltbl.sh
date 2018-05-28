#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
abi="$3"
prefix="$4"
offset="$5"

nxt=0
grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in" | sort -n | (
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
    
    if [ "$abi" = "32-o32" ]; then
	while read nr name entry compat config comment ; do
	    while [ $nxt -lt $nr ]; do
		if [ $(($nxt % 5)) -eq 0 ]; then
		    echo -e "\tPTR\tsys_ni_syscall\t/* $nxt */"
		else
		    echo -e "\tPTR\tsys_ni_syscall"
		fi
		let nxt=nxt+1
	    done
	    
	    if [ -z "$config" -o "$config" = "-" ]; then
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\tPTR\t${entry}\t/* $nxt */"
		else
		    echo -e "\tPTR\t${entry}"
		fi
	    else
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
		    if [ $(($nr % 5)) -eq 0 ]; then
			echo -e "\tPTR\t${i_entry}\t/* $nxt */"
		    else
			echo -e "\tPTR\t${i_entry}"
		    fi
		fi
		if [ "$e_entry" != "-" ]; then
		    echo "#else"
		    if [ $(($nr % 5)) -eq 0 ]; then
			echo -e "\tPTR\t${e_entry}\t/* $nxt */"
		    else
			echo -e "\tPTR\t${e_entry}"
		    fi
		fi
		echo "#endif"
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done
    else
	while read nr name entry compat comment ; do
	    while [ $nxt -lt $nr ]; do
		if [ $(($nxt % 5)) -eq 0 ]; then
		    echo -e "\tPTR\tsys_ni_syscall\t/* $nxt */"
		else
		    echo -e "\tPTR\tsys_ni_syscall"
		fi
		let nxt=nxt+1
	    done

	    if [ "$abi" = "64-o32" ]; then
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\tPTR\t${compat}\t/* $nxt */"
		else
		    echo -e "\tPTR\t${compat}"
		fi
	    else
		if [ $(($nr % 5)) -eq 0 ]; then
		    echo -e "\tPTR\t${entry}\t/* $nxt */"
		else
		    echo -e "\tPTR\t${entry}"
		fi
	    fi
	    nxt=$nr
	    let nxt=nxt+1
	done
    fi

    if [ "$abi" = "64-o32" ]; then
	echo -e "\t.size\tsys32_call_table,.-sys32_call_table"
    elif [ "$abi" = "64-64" ]; then
	echo -e "\t.size\tsys_call_table,.-sys_call_table"
    elif [ "$abi" = "64-n32" ]; then
	echo -e "\t.size\tsysn32_call_table,.-sysn32_call_table"
    fi
) > "$out"
