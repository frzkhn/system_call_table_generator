# ia64 architecture 
uapih := arch/$(SRCARCH)/include/uapi/asm
uapis := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(uapis)' ] || mkdir -p '$(uapis)')

syscall32 := $(srctree)/$(src)/syscall_32.tbl

syshdr := $(srctree)/$(src)/syscallhdr.sh
systbl := $(srctree)/$(src)/syscalltbl.sh

quiet_cmd_syshdr = SYSHDR  $@
      cmd_syshdr = $(CONFIG_SHELL) '$(syshdr)' '$<' '$@' \
		   '$(syshdr_abi_$(basetarget))' \
		   '$(syshdr_pfx_$(basetarget))' \
		   '$(syshdr_offset_$(basetarget))'

quiet_cmd_systbl = SYSTBL  $@
      cmd_systbl = $(CONFIG_SHELL) '$(systbl)' $< $@ 

syshdr_abi_unistd_32 := common
$(uapih)/unistd_32.h: $(syscall32) $(syshdr)
	$(call if_changed,syshdr)

$(uapis)/entry.S: $(syscall32) $(systbl)
	$(call if_changed,systbl)

uapihsyshdr-y			+= unistd_32.h
uapissyshdr-y			+= entry.S

targets	+= $(uapihsyshdr-y) $(uapissyshdr-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyshdr-y))
all: $(addprefix $(uapis)/,$(uapissyshdr-y))
	@:
