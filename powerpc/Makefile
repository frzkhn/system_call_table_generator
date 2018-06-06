# SPDX-License-Identifier: GPL-2.0
out := arch/$(SRCARCH)/include/generated/asm
uapi := arch/$(SRCARCH)/include/generated/uapi/asm

_dummy := $(shell [ -d '$(uapi)' ] || mkdir -p '$(uapi)') \
	  $(shell [ -d '$(out)' ] || mkdir -p '$(out)')

syscall := $(srctree)/$(src)/syscall.tbl

syshdr := $(srctree)/$(src)/syscallhdr.sh
systbl := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syshdr = SYSHDR  $@
      cmd_syshdr = $(CONFIG_SHELL) '$(syshdr)' '$<' '$@'  \
		   '$(syshdr_abi_$(basetarget))'          \
		   '$(syshdr_pfx_$(basetarget))'          \
		   '$(syshdr_offset_$(basetarget))'

quiet_cmd_systbl = SYSTBL  $@
      cmd_systbl = $(CONFIG_SHELL) '$(systbl)' '$<' '$@'  \
		   '$(systbl_abi_$(basetarget))'

$(uapi)/unistd.h: $(syscall) $(syshdr)
	$(call if_changed,syshdr)

systbl_abi_syscalls_32 := 32
$(out)/syscalls_32.h: $(syscall) $(systbl)
	$(call if_changed,systbl)

systbl_abi_syscalls_64 := 64
$(out)/syscalls_64.h: $(syscall) $(systbl)
	$(call if_changed,systbl)

systbl_abi_syscalls_x32 := x32
$(out)/syscalls_x32.h: $(syscall) $(systbl)
	$(call if_changed,systbl)

uapisyshdr-y			+= unistd.h
syshdr-y			+= syscalls_32.h syscalls_64.h syscalls_x32.h

targets	+= $(uapisyshdr-y) $(syshdr-y)

PHONY += all
all: $(addprefix $(uapi)/,$(uapisyshdr-y))
all: $(addprefix $(out)/,$(syshdr-y))
	@:
