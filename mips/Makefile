# SPDX-License-Identifier: GPL-2.0
out := arch/$(SRCARCH)/include/generated/asm
uapi := arch/$(SRCARCH)/include/generated/uapi/asm

_dummy := $(shell [ -d '$(uapi)' ] || mkdir -p '$(uapi)') \
	  $(shell [ -d '$(out)' ] || mkdir -p '$(out)')

syscall32 := $(srctree)/$(src)/syscall_32.tbl
syscall64 := $(srctree)/$(src)/syscall_64.tbl
syscalln32 := $(srctree)/$(src)/syscall_n32.tbl

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

syshdr_abi_unistd_32 := 32
syshdr_offset_unistd_32 := __NR_Linux
$(uapi)/unistd_32.h: $(syscall32) $(syshdr)
	$(call if_changed,syshdr)

syshdr_abi_unistd_64 := 64
syshdr_offset_unistd_64 := __NR_Linux
$(uapi)/unistd_64.h: $(syscall64) $(syshdr)
	$(call if_changed,syshdr)

syshdr_abi_unistd_n32 := n32
syshdr_offset_unistd_n32 := __NR_Linux
$(uapi)/unistd_n32.h: $(syscalln32) $(syshdr)
	$(call if_changed,syshdr)

systbl_abi_syscalls_32_o32 := 32-o32
$(out)/syscalls_32_o32.h: $(syscall32) $(systbl)
	$(call if_changed,systbl)

systbl_abi_syscalls_64_o32 := 64-o32
$(out)/syscalls_64_o32.h: $(syscall32) $(systbl)
	$(call if_changed,systbl)

systbl_abi_syscalls_64_64 := 64-64
$(out)/syscalls_64_64.h: $(syscall64) $(systbl)
	$(call if_changed,systbl)

systbl_abi_syscalls_64_n32 := 64-n32
$(out)/syscalls_64_n32.h: $(syscalln32) $(systbl)
	$(call if_changed,systbl)

uapisyshdr-y			+= unistd_32.h unistd_64.h unistd_n32.h
syshdr-y			+= syscalls_32_o32.h syscalls_64_o32.h syscalls_64_64.h syscalls_64_n32.h

targets	+= $(uapisyshdr-y) $(syshdr-y)

PHONY += all
all: $(addprefix $(uapi)/,$(uapisyshdr-y))
all: $(addprefix $(out)/,$(syshdr-y))
	@:
