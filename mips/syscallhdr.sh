#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in="$1"
out="$2"
my_abi="$3"
prefix="$4"
offset="$5"

fileguard=_UAPI_ASM_MIPS_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#include <asm/sgidefs.h>"
    echo ""

    if [ "$my_abi" = "32" ]; then
	echo "#if _MIPS_SIM == _MIPS_SIM_ABI32"
	echo ""
	echo -e "#define __NR_Linux\t4000"
	base=4000
    elif [ "$my_abi" = "64" ]; then
	echo "#if _MIPS_SIM == _MIPS_SIM_ABI64"
	echo ""
	echo -e "#define __NR_Linux\t5000"
	base=5000
    elif [ "$my_abi" = "n32" ]; then
	echo "#if _MIPS_SIM == _MIPS_SIM_NABI32"
	echo ""
	echo -e "#define __NR_Linux\t6000"
	base=6000
    fi

    while read nr abi name entry compat ; do
	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$base)))"
	fi
    done

    echo ""
    if [ "$my_abi" = "32" ]; then
	echo -e "#define __NR_Linux_syscalls\t366"
	echo ""
	echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI32 */"
	echo ""
	echo -e "#define __NR_O32_Linux\t4000"
	echo -e "#define __NR_O32_Linux_syscalls\t366"
    elif [ "$my_abi" = "64" ]; then
	echo -e "#define __NR_Linux_syscalls\t326"
	echo ""
	echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI64 */"
	echo ""
	echo -e "#define __NR_64_Linux\t5000"
	echo -e "#define __NR_64_Linux_syscalls\t326"
    elif [ "$my_abi" = "n32" ]; then
	echo -e "#define __NR_Linux_syscalls\t330"
	echo ""
	echo "#endif /* _MIPS_SIM == _MIPS_SIM_NABI32 */"
	echo ""
	echo -e "#define __NR_N32_Linux\t6000"
	echo -e "#define __NR_N32_Linux_syscalls\t330"
    fi
    echo ""
    echo "#endif /* ${fileguard} */"
) > "$out"
