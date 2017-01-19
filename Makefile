user :=
group :=
private :=

PILLAR_PAIRS :=

ifdef private
PILLAR_PAIRS += 'private':$(private),
endif
ifdef user
PILLAR_PAIRS += 'user':'$(user)',
endif
ifdef group
PILLAR_PAIRS += 'group':'$(group)',
endif

PILLAR = {$(PILLAR_PAIRS)}

EXEC := $(if $(DRYRUN),@echo '[DRYRUN]',)
SALT_ARGS :=

install:
	$(EXEC) salt-call $(SALT_ARGS) state.apply pillar="$(PILLAR)"

uninstall:
	$(EXEC) salt-call $(SALT_ARGS) state.apply dotfiles.uninstall pillar="$(PILLAR)"

all uninstall-all: PILLAR_PAIRS += 'private':True,
all: install
uninstall-all: uninstall

pillar:
	@echo "$(PILLAR)"

.PHONY: install uninstall pillar