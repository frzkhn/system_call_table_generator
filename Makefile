# Alpha Architecture 
uapih := arch/$(SRCARCH)/include/uapi/asm
uapis := arch/$(SRCARCH)/kernel

_dummy := $(shell [ -d '$(uapih)' ] || mkdir -p '$(uapih)') \
	  $(shell [ -d '$(uapis)' ] || mkdir -p '$(uapis)')

syscall := $(srctree)/$(src)/syscall.tbl

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
$(uapih)/unistd.h: $(syscall) $(syshdr)
	$(call if_changed,syshdr)

$(uapis)/systbls.S: $(syscall) $(systbl)
	$(call if_changed,systbl)

uapihsyshdr-y			+= unistd.h
uapissyshdr-y			+= systbls.S

targets	+= $(uapihsyshdr-y) $(uapissyshdr-y)

PHONY += all
all: $(addprefix $(uapih)/,$(uapihsyshdr-y))
all: $(addprefix $(uapis)/,$(uapissyshdr-y))
	@:
