# alpha: system_call_table_generator

- This architecture does have single ABI.
  syscall.tbl contains the information like 
    - system call number
    - name 
    - entry
    - comments

- The scripts syscallhdr.sh will generate 
  uapi header in the location, 
  arch/alpha/include/generated/uapi/asm/unistd.h

- The script syscalltbl.sh will generate 
  system call table support file in the location, 
  arch/alpha/include/generated/asm/syscalls.h
  which will be included by system call table, 
  arch/alpha/kernel/syscall.S

