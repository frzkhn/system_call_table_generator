# xtensa architecture 
uapih := arch/$(SRCARCH)/include/uapi/asm

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)')

syscalltbl := $(srctree)/$(src)/syscall.tbl
syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

syscall_abi_unistd_32 := common
$(uapih)/unistd.h: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h

targets	+= $(uapihsyscall-y) $(uapissyscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
	@:
