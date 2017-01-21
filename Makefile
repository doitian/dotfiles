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
SALT_ARGS := --state-output=mixed

install: sls

uninstall: SLS := dotfiles.uninstall
build build-all: SLS := dotfiles.build
repos repos-all: SLS := dotfiles.repos

all build-all repos-all: PILLAR_PAIRS += 'private':True,
uninstall all build build-all repos repos-all: sls

pillar:
	@echo "$(PILLAR)"

sls: config/minion
	$(EXEC) salt-call $(SALT_ARGS) state.apply $(SLS) pillar="$(PILLAR)"

config/minion:
	bin/setup

.PHONY: install uninstall repos build build-all repos-all all pillar sls
