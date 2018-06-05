# xtensa: system_call_table_generator

- This architecture does have single ABI.
  syscall.tbl contains the information like 
    - system call number
    - name 
    - entry
    - comments

- The scripts syscallhdr.sh will generate uapi header- 
  arch/xtensa/include/uapi/asm/unistd.h. 

- The script syscalltbl.sh will generate syscalls.h 
  which will be included by syscall.S file