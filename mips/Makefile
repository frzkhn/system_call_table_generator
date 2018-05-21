# SPDX-License-Identifier: GPL-2.0
uapih := arch/$(SRCARCH)/include/uapi/asm
scall := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(scall)' ] || mkdir -p '$(scall)')

systbl32 := $(srctree)/$(src)/syscall_32.tbl
systbl64 := $(srctree)/$(src)/syscall_64.tbl
systbln32 := $(srctree)/$(src)/syscall_n32.tbl

syscallhdr := $(srctree)/$(src)/syscallhdr.sh
syscalltbl := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syscallhdr = SYSCALLHDR  $@
      cmd_syscallhdr = $(CONFIG_SHELL) '$(syscallhdr)'     \
		      '$(systbl32)' '$(systbl64)'          \
		      '$(systbln32)' '$(uapih)/unistd.h'   \
		      '$(syscallhdr_abi_$(basetarget))'    \
		      '$(syscallhdr_pfx_$(basetarget))'    \
		      '$(syscallhdr_offset_$(basetarget))'

quiet_cmd_syscalltbl = SYSCALLTBL  $@
      cmd_syscalltbl = $(CONFIG_SHELL) '$(syscalltbl)' '$<' '$@' \
		      '$(syscalltbl_abi_$(basetarget))'          \
		      '$(syscalltbl_pfx_$(basetarget))'          \
		      '$(syscalltbl_offset_$(basetarget))'

syscallhdr_offset_unistd := __NR_Linux
$(uapih)/unistd.h: $(systbl32) $(systbl64) $(systbln32) $(syscallhdr)
	$(call if_changed,syscallhdr)

syscalltbl_abi_systbl32-o32 := 32-o32
$(scall)/systbl32-o32.S: $(systbl32) $(syscalltbl)
	$(call if_changed,syscalltbl)

syscalltbl_abi_systbl64-o32 := 64-o32
$(scall)/systbl64-o32.S: $(systbl32) $(syscalltbl)
	$(call if_changed,syscalltbl)

syscalltbl_abi_systbl64-64 := 64-64
$(scall)/systbl64-64.S: $(systbl64) $(syscalltbl)
	$(call if_changed,syscalltbl)

syscalltbl_abi_systbl64-n32 := 64-n32
$(scall)/systbl64-n32.S: $(systbln32) $(syscalltbl)
	$(call if_changed,syscalltbl)

uapihsyscall-y			+= unistd.h
syscall-y			+= systbl32-o32.S systbl64-o32.S systbl64-64.S systbl64-n32.S

targets	+= $(uapihsyscall-y) $(syscall-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyscall-y))
all: $(addprefix $(scall)/,$(syscall-y))
	@:
