# system_call_table_generator

- Add microblaze script
      <- Modify syscall.tbl to e_syscall.tbl by hand.>
      - Join the syscall.tbl and e_syscall.tbl
      	$ join -a1 syscall.tbl e_syscall.tbl  | grep -v \# | while read a b c d e ; do echo -e "$a\t$b\t$c\tsys_$e" ; done tmp.tbl
	$ sed -e 's:\<sys_\>:sys_ni_syscall:' tmp.tbl > syscall.tbl
NOTE: Marcin's script will generate syscall.tbl
      - Create syscalltbl.sh(new) by combine syscallhdr.sh and syscalltbl.sh
      - Modify to Makefile to support syscalltbl.sh
      - Validate the script by replacing arch/x86/entry/syscalls/*