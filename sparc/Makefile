# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
scall := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(scall)' ] || mkdir -p '$(scall)')

systbl := $(srctree)/$(src)/syscall.tbl
syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

$(uapih)/unistd.h: $(systbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls_32 := 32
$(scall)/systbls_32.S: $(systbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls_64 := 64
$(scall)/systbls_64.S: $(systbl) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
syscall-y			+= systbls_32.S	systbls_64.S 

targets	+= $(uapihsyscall-y) $(syscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(scall)/,$(syscall-y))
	@:
