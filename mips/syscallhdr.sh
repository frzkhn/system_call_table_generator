#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

in_32="$1"
in_64="$2"
in_n32="$3"
out="$4"
abi="$5"
prefix="$6"
offset="$7"

hdr_footer_32() {
    echo ""
    echo "/*"
    echo " * Offset of the last Linux o32 flavoured syscall"
    echo " */"
    echo -e "#define __NR_Linux_syscalls\t366"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI32 */"
    echo ""
    echo -e "#define __NR_O32_Linux\t4000"
    echo -e "#define __NR_O32_Linux_syscalls\t366"
    echo ""
}

hdr_out() {
    nr="$1"
    name="$2"
    base="$3"

    if [ -z "$offset" ]; then
	echo -e "#define __NR_${prefix}${name}\t$nr"
    else
	echo -e "#define __NR_${prefix}${name}\t($offset + $(($nr-$base)))"
    fi
}

hdr_header_32() {
    echo "#if _MIPS_SIM == _MIPS_SIM_ABI32"
    echo ""
    echo "/*"
    echo " * Linux o32 style syscalls are in the range from 4000 to 4999."
    echo " */"
    echo -e "#define __NR_Linux\t4000"
}

hdr_header() {
    echo "/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */"
    echo "/*"
    echo " * This file is subject to the terms and conditions of the GNU General Public"
    echo " * License.  See the file "\"COPYING"\" in the main directory of this archive"
    echo " * for more details."
    echo " *"
    echo " * Copyright (C) 1995, 96, 97, 98, 99, 2000 by Ralf Baechle"
    echo " * Copyright (C) 1999, 2000 Silicon Graphics, Inc."
    echo " *"
    echo " * Changed system calls macros _syscall5 - _syscall7 to push args 5 to 7 onto"
    echo " * the stack. Robin Farine for ACN S.A, Copyright (C) 1996 by ACN S.A"
    echo " */"
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""
    echo "#include <asm/sgidefs.h>"
    echo ""
}

hdr_fileguard() {
    fileguard=_UAPI_ASM_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
}

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in_32" | sort -n | (
    hdr_fileguard
    hdr_header
    hdr_header_32
    
    base=4000
    while read nr name entry compat comment ; do
	 hdr_out $nr $name $base
    done

    hdr_footer_32
) > "$out"

hdr_footer() {
    echo ""
    echo "#endif /* ${fileguard} */"
}

hdr_footer_64() {
    echo ""
    echo "/*"
    echo " * Offset of the last Linux 64-bit flavoured syscall"
    echo " */"
    echo -e "#define __NR_Linux_syscalls\t326"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_ABI64 */"
    echo ""
    echo -e "#define __NR_64_Linux\t5000"
    echo -e "#define __NR_64_Linux_syscalls\t326"
    echo ""
}

hdr_header_64() {
    echo "#if _MIPS_SIM == _MIPS_SIM_ABI64"
    echo ""
    echo "/*"
    echo " * Linux 64-bit syscalls are in the range from 5000 to 5999."
    echo " */"
    echo -e "#define __NR_Linux\t5000"
}

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in_64" | sort -n | (
    hdr_header_64

    base=5000
    while read nr name entry comment ; do
	hdr_out $nr $name $base
    done

    hdr_footer_64
) >> "$out"

hdr_footer_n32() {
    echo ""
    echo "/*"
    echo " * Offset of the last N32 flavoured syscall"
    echo " */"
    echo -e "#define __NR_Linux_syscalls\t330"
    echo ""
    echo "#endif /* _MIPS_SIM == _MIPS_SIM_NABI32 */"
    echo ""
    echo -e "#define __NR_N32_Linux\t6000"
    echo -e "#define __NR_N32_Linux_syscalls\t330"
}

hdr_header_n32() {
    echo "#if _MIPS_SIM == _MIPS_SIM_NABI32"
    echo ""
    echo "/*"
    echo " * Linux N32 syscalls are in the range from 6000 to 6999."
    echo " */"
    echo -e "#define __NR_Linux\t6000"
}

grep -E "^[0-9A-Fa-fXx]+[[:space:]]" "$in_n32" | sort -n | (
    hdr_fileguard
    hdr_header_n32

    base=6000
    while read nr name entry comment ; do
	hdr_out $nr $name $base
    done

    hdr_footer_n32
    hdr_footer
) >> "$out"
