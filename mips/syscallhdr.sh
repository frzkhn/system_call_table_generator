#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in_32="$1"
in_64="$2"
in_n32="$3"
out="$4"
abi="$5"
prefix="$6"
offset="$7"

fileguard=_UAPI_ASM_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in_32" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#include <asm/sgidefs.h>"
    echo ""
    echo "#if _MIPS_SIM == _MIPS_SIM_ABI32"
    echo ""
    echo -e "#define __NR_Linux\t4000"
    
    base=4000
    while read nr name entry compat comment ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$base)))"
	fi
    done

    echo ""
    echo -e "#define __NR_Linux_syscalls\t366"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI32 */"
    echo ""
    echo -e "#define __NR_O32_Linux\t4000"
    echo -e "#define __NR_O32_Linux_syscalls\t366"
    echo ""
) > "$out"

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in_64" | sort -n | (
    echo "#if _MIPS_SIM == _MIPS_SIM_ABI64"
    echo ""
    echo -e "#define __NR_Linux\t5000"

    base=5000
    while read nr name entry comment ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$base)))"
	fi
    done

    echo ""
    echo -e "#define __NR_Linux_syscalls\t326"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI64 */"
    echo ""
    echo -e "#define __NR_64_Linux\t5000"
    echo -e "#define __NR_64_Linux_syscalls\t326"
    echo ""
) >> "$out"

grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in_n32" | sort -n | (
    echo "#if _MIPS_SIM == _MIPS_SIM_NABI32"
    echo ""
    echo -e "#define __NR_Linux\t6000"

    base=6000
    while read nr name entry comment ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$base)))"
	fi
    done

    echo -e "#define __NR_Linux_syscalls\t330"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_NABI32 */"
    echo ""
    echo -e "#define __NR_N32_Linux\t6000"
    echo -e "#define __NR_N32_Linux_syscalls\t330"
    echo ""
    echo "#endif /* ${fileguard} */"
) >> "$out"
