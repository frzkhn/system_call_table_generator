# system_call_table_generator

- Add microblaze script
      - Modify syscall.tbl to e_syscall.tbl by hand. 
NOTE: Marcin's script will generate syscall.tbl
      - Create syscalltbl.sh(new) by combine syscallhdr.sh and syscalltbl.sh
      - Modify to Makefile to support syscalltbl.sh
      - Validate the script by replacing arch/x86/entry/syscalls/*