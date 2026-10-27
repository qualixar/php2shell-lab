.PHONY: up check demo hunt down lint
up:     ## start both containers (127.0.0.1:8081 legacy, :8082 patched)
	docker compose up -d
check:  ## ask each web runtime which PHP it serves
	-./php2shell-check.sh http://127.0.0.1:8081/runtime.php
	-./php2shell-check.sh http://127.0.0.1:8082/runtime.php
demo:   ## the restart trap, step by step
	./scripts/restart-trap-demo.sh
hunt:   ## read-only first look at the legacy container
	./scripts/hunt.sh legacy
down:   ## stop and remove everything
	docker compose down --remove-orphans
lint:
	shellcheck php2shell-check.sh scripts/*.sh
