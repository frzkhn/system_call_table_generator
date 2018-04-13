 # sh architecture 
uapih := arch/$(SRCARCH)/include/uapi/asm
uapis := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(uapis)' ] || mkdir -p '$(uapis)')

syscalltbl32 := $(srctree)/$(src)/syscall_32.tbl
e_syscalltbl32 := $(srctree)/$(src)/e_syscall_32.tbl
syscalltbl64 := $(srctree)/$(src)/syscall_64.tbl
e_syscalltbl64 := $(srctree)/$(src)/e_syscall_64.tbl

syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

syscall_abi_unistd_32 := 32
$(uapih)/unistd_32.h: $(syscalltbl32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_unistd_64 := 64
$(uapih)/unistd_64.h: $(syscalltbl64) $(syscall)
	$(call if_changed,syscall)

$(uapis)/syscalls_32.S: $(e_syscalltbl32) $(syscall)
	$(call if_changed,syscall)

$(uapis)/syscalls_64.S: $(e_syscalltbl64) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd_32.h unistd_64.h
uapissyscall-y			+= syscalls_32.S syscalls_64.S

targets	+= $(uapihsyscall-y) $(uapissyscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(uapis)/,$(uapissyscall-y))
	@:
