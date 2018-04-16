# system_call_table_generator

- Add sh script
      > - Modify syscall.tbl to e_syscall.tbl by hand.
      - Join the syscall_32/64.tbl and e_syscall_32/64.tbl
        $ join -a1 syscall_32/64.tbl e_syscall_32/64.tbl  | grep -v \# | while read a b c d e ; do echo -e "$a\t$b\t$c\tsys_$e" ; done > tmp_32/64.tbl
        $ sed -e 's:\<sys_\>:sys_ni_syscall:' tmp_32/64.tbl > syscall_32/64.tbl
NOTE: Marcin's script will generate syscall.tbl
      - Create syscalltbl.sh(new) by combine syscallhdr.sh and syscalltbl.sh
      - Modify to Makefile to support syscalltbl.sh
      - Validate the script by replacing arch/x86/entry/syscalls/*