#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

fileguard=_UAPI_ASM_IA64_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#include <asm/break.h>"
    echo ""
    echo -e "#define __BREAK_SYSCALL\t__IA64_BREAK_SYSCALL"
    echo ""

    while read nr abi name entry ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
        fi
    done

    echo ""
    echo "#endif /* ${fileguard} */"
) > "$out"
