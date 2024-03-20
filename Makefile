install:
	./manage.sh i -p

repo r:
	./manage.sh r -p

gitpod-debug:
	gitpod_evars="$${!GITPOD_*}" gp_evars="$${!GP_*}"; for k in $${gitpod_evars:-} $${gp_evars:-}; do dargs+=(-e "$${k}"); done; docker run "$${dargs[@]}" --net=host --rm -v $$PWD:/home/gitpod/.dotfiles -v /workspace:/workspace -v /ide:/ide -v /usr/bin/gp:/usr/bin/gp:ro -v /.supervisor:/.supervisor -v /var/run/docker.sock:/var/run/docker.sock --privileged -it gitpod/workspace-full bash -c 'trap "echo -e \"=== Run \033[1;32mexit\033[0m command to leave debug workspace\"; exec bash -li" EXIT ERR; echo "PROMPT_COMMAND=\"echo -n \\\"[debug-workspace] \\\"; \$$PROMPT_COMMAND\"" >> $$HOME/.bashrc; eval "$$(gp env -e)"; dot_path="$${HOME}/.dotfiles"; for s in install setup bootstrap; do if p="$${dot_path}/$${s}" && test -x "$${p}" || p="$${p}.sh" && test -x "$${p}"; then set +m; "$$p"; set -m; exit; fi; done; while read -r file; do rf_path="$${file#"$${dot_path}"/}"; target_file="$${HOME}/$${rf_path}"; target_dir="$${target_file%/*}"; if test ! -d "$$target_dir"; then mkdir -p "$$target_dir"; fi; ln -sf "$$file" "$$target_file"; done < <(find "$${dot_path}" -type f);'

.PHONY: install repo r gitpod-debug
