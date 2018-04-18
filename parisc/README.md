# system_call_table_generator

- Add pa-risc script
      > - Modify syscall.tbl to e_syscall.tbl by hand.
      $ join -a1 syscall.tbl e_syscall.tbl  | grep -v \# | while read a b c d e ; do echo -e "$a\t$b\t$c\tENTRY_SAME($e)" ; done > syscall.tbl
NOTE: Marcin's script will generate syscall.tbl
      - Create syscalltbl.sh(new) by combine syscallhdr.sh and syscalltbl.sh
      - Modify to Makefile to support syscalltbl.sh
      - Validate the script by replacing arch/x86/entry/syscalls/*