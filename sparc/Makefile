# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
uapis := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(uapis)' ] || mkdir -p '$(uapis)')

syscalltbl := $(srctree)/$(src)/syscall.tbl

syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

$(uapih)/unistd.h: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls_32 := 32
$(uapis)/systbls_32.S: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls_x32 := x32 
$(uapis)/systbls_x32.S: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls_64 := 64
$(uapis)/systbls_64.S: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
uapissyscall-y			+= systbls_32.S	systbls_64.S systbls_x32.S

targets	+= $(uapihsyscall-y) $(uapissyscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(uapis)/,$(uapissyscall-y))
	@:
