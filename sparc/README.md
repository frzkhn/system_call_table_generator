# sparc: system_call_table_generator

- This architecture does have single ABI.
  syscall.tbl contains the information like 
    - system call number
    - name 
    - entry_64
    - entry_32
    - compat
    - comments

- The scripts syscallhdr.sh will generate uapi header- 
  arch/sparc/include/uapi/asm/unistd.h. 

- The script syscalltbl.sh will generate syscalls.h 
  which will be included by syscall_64/32/x32.S file

