#!/bin/sh

in="$1"
out="$2"
my_abis=`echo "($3)" | tr ',' '|'`
prefix="$4"
offset="$5"

fileguard=_UAPI_ASM_ALPHA_`basename "$out" | sed \
    -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' \
    -e 's/[^A-Z0-9_]/_/g' -e 's/__/_/g'`
grep -E "^[0-9A-Fa-fXx]+[[:space:]]+${my_abis}" "$in" | sort -n | (
    echo "#ifndef ${fileguard}"
    echo "#define ${fileguard}"
    echo ""

    while read nr abi name entry ; do
	if [ "$nr" -eq 300 ]; then
	echo "
#define __IGNORE_alarm
#define __IGNORE_creat
#define __IGNORE_getegid
#define __IGNORE_geteuid
#define __IGNORE_getgid
#define __IGNORE_getpid
#define __IGNORE_getppid
#define __IGNORE_getuid
#define __IGNORE_pause
#define __IGNORE_time
#define __IGNORE_utime
#define __IGNORE_umount2
"
	fi

	if [ -z "$offset" ]; then
	    echo -e "#define __NR_${prefix}${name}\t$nr"
	else
	    echo -e "#define __NR_${prefix}${name}\t($offset + $nr)"
        fi
    done

    echo "
#define __IGNORE_pkey_mprotect
#define __IGNORE_pkey_alloc
#define __IGNORE_pkey_free
"
    echo "#endif /* ${fileguard} */"
) > "$out"
