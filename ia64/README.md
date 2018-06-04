# ia64: system_call_table_generator

- This architecture does have single ABI.
  syscall.tbl contains the information like 
    - system call number
    - name 
    - entry
    - comments

- The scripts syscallhdr.sh will generate uapi header- 
  arch/ia64/include/uapi/asm/unistd.h. 

- The script syscalltbl.sh will generate system calls
  header arch/ia64/include/asm/syscalls.h, which will
  be included by syscall.c file


