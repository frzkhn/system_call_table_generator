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

syscall_abi_unistd := common
$(uapih)/unistd.h: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbls := common
$(uapis)/systbls.S: $(syscalltbl) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
uapissyscall-y			+= systbls.S

targets	+= $(uapihsyscall-y) $(uapissyscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(uapis)/,$(uapissyscall-y))
	@:
