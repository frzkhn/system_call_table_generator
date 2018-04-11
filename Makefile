# xtensa architecture 
uapih := arch/$(SRCARCH)/include/uapi/asm

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)')

syscall := $(srctree)/$(src)/syscall.tbl

syshdr := $(srctree)/$(src)/syscallhdr.sh

quiet_cmd_syshdr = SYSHDR  $@
      cmd_syshdr = $(CONFIG_SHELL) '$(syshdr)' '$<' '$@' \
		   '$(syshdr_abi_$(basetarget))' \
		   '$(syshdr_pfx_$(basetarget))' \
		   '$(syshdr_offset_$(basetarget))'

syshdr_abi_unistd_32 := common
$(uapih)/unistd.h: $(syscall) $(syshdr)
	$(call if_changed,syshdr)

uapihsyshdr-y			+= unistd.h

targets	+= $(uapihsyshdr-y) $(uapissyshdr-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyshdr-y))
	@:
