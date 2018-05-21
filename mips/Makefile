# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
scall := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(scall)' ] || mkdir -p '$(scall)')

systbl32 := $(srctree)/$(src)/syscall_32.tbl
systbl64 := $(srctree)/$(src)/syscall_64.tbl
systbln32 := $(srctree)/$(src)/syscall_n32.tbl
syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

syscall_abi_unistd := 32_o32
syscall_offset_unistd := __NR_Linux
$(uapih)/unistd.h: $(systbl32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl_32 := 32
$(scall)/systbl_32.S: $(systbl32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl_o32 := 64_o32
$(scall)/systbl_o32.S: $(systbl32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl_64 := 64
$(scall)/systbl_64.S: $(systbl64) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl_n32 := 64_n32
$(scall)/systbl_n32.S: $(systbln32) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
syscall-y			+= systbl_32.S systbl_o32.S systbl_64.S systbl_n32.S

targets	+= $(uapihsyscall-y) $(syscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(scall)/,$(syscall-y))
	@:
