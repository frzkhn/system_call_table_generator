# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
uapis := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(uapis)' ] || mkdir -p '$(uapis)')

syscalltblo32 := $(srctree)/$(src)/syscall_o32.tbl
syscalltbl64 := $(srctree)/$(src)/syscall_64.tbl
syscalltbl64n32 := $(srctree)/$(src)/syscall_64n32.tbl
syscall := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscall = SYSCALL  $@
      cmd_syscall = $(CONFIG_SHELL) '$(syscall)' '$<' '$@' \
		   '$(syscall_abi_$(basetarget))' \
		   '$(syscall_pfx_$(basetarget))' \
		   '$(syscall_offset_$(basetarget))'

syscall_abi_unistd := 32-o32
syscall_offset_unistd := __NR_Linux
$(uapih)/unistd.h: $(syscalltblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl32_o32 := 32-o32
$(uapis)/systbl32_o32.S: $(syscalltblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_o32 := 64-o32
$(uapis)/systbl64_o32.S: $(syscalltblo32) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_64 := 64-64
$(uapis)/systbl64_64.S: $(syscalltbl64) $(syscall)
	$(call if_changed,syscall)

syscall_abi_systbl64_n32 := 64-n32
$(uapis)/systbl64_n32.S: $(syscalltbl64n32) $(syscall)
	$(call if_changed,syscall)

uapihsyscall-y			+= unistd.h
uapissyscall-y			+= systbl32_o32.S systbl64_o32.S systbl64_64.S systbl64_n32.S

targets	+= $(uapihsyscall-y) $(uapissyscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(uapis)/,$(uapissyscall-y))
	@:
