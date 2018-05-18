# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
scall := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(scall)' ] || mkdir -p '$(scall)')

systblo32 := $(srctree)/$(src)/syscall_o32.tbl
systbl64 := $(srctree)/$(src)/syscall_64.tbl
systbl64n32 := $(srctree)/$(src)/syscall_64n32.tbl
syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

syscall_abi_unistd := 32_o32
syscall_offset_unistd := __NR_Linux
$(uapih)/unistd.h: $(systblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl32_o32 := 32_o32
$(scall)/systbl32_o32.S: $(systblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_o32 := 64_o32
$(scall)/systbl64_o32.S: $(systblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_64 := 64_64
$(scall)/systbl64_64.S: $(systbl64) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_n32 := 64_n32
$(scall)/systbl64_n32.S: $(systbl64n32) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
syscall-y			+= systbl32_o32.S systbl64_o32.S systbl64_64.S systbl64_n32.S

targets	+= $(uapihsyscall-y) $(syscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(scall)/,$(syscall-y))
	@:
