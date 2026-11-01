# StratasLocal Makefile
# Phase 1: Linux Baseline as Code
#
# Usage:
#   make up              - build images and start all containers
#   make down            - stop and remove containers
#   make build           - build images only
#   make test-linux      - run bats tests inside containers (fast, CI-safe)
#   make test-linux-vm   - vagrant up + run VM bats tests (local only, ~3 min)
#   make lint            - run hadolint, shellcheck, yamllint
#   make harden          - run harden.sh inside all nodes
#   make idempotent      - run harden.sh a second time to verify zero changes

COMPOSE_FILE := linux/compose/docker-compose.yml
COMPOSE      := docker compose -f $(COMPOSE_FILE)
NODES        := web-node01 web-node02 web-node03 data-node01

.PHONY: up down build test-linux test-linux-vm lint harden idempotent help

## up: Build images (if needed) and start all containers in the background
up:
	$(COMPOSE) up -d --build

## down: Stop and remove all containers (volumes are preserved)
down:
	$(COMPOSE) down

## build: Build container images without starting them
build:
	$(COMPOSE) build

## test-linux: Run bats hardening tests inside web-node01
test-linux:
	@echo "==> Running hardening tests on web-node01..."
	docker exec web-node01 bats /tests/container/hardening.bats
	@echo "==> Running hardening tests on web-node02..."
	docker exec web-node02 bats /tests/container/hardening.bats
	@echo "==> Running hardening tests on data-node01..."
	docker exec data-node01 bats /tests/container/hardening.bats

## harden: Run harden.sh inside all node containers
harden:
	@for node in $(NODES); do \
		echo "==> Hardening $$node..."; \
		docker exec -u root $$node bash /harden.sh; \
	done

## idempotent: Run harden.sh a second time — expect ZERO changes
idempotent:
	@echo "==> Idempotency check: running harden.sh a second time on web-node01..."
	docker exec -u root web-node01 bash /harden.sh 2>&1 | tee /tmp/idempotent-check.txt
	@echo "==> Checking for CHANGED lines..."
	@if grep -q "^\\[harden\\] CHANGED:" /tmp/idempotent-check.txt; then \
		echo "FAIL: Script made changes on second run (not idempotent)"; \
		grep "^\\[harden\\] CHANGED:" /tmp/idempotent-check.txt; \
		exit 1; \
	else \
		echo "PASS: Zero changes on second run — script is idempotent."; \
	fi

## lint: Run all linters (hadolint, shellcheck, yamllint)
lint:
	@echo "==> hadolint: Dockerfiles..."
	@find linux/dockerfiles -name Dockerfile | xargs hadolint
	@echo "==> shellcheck: shell scripts..."
	@find linux -name "*.sh" | xargs shellcheck
	@echo "==> yamllint: YAML files..."
	@find linux/compose -name "*.yml" | xargs yamllint

## test-linux-vm: Boot the Vagrant VM and run SELinux + firewalld bats tests (local only)
test-linux-vm:
	@echo "==> Booting Vagrant VM (libvirt)..."
	cd linux/vm && vagrant up
	@echo "==> Running VM bats tests..."
	cd linux/vm && vagrant ssh -c "sudo bats /vagrant/tests/vm/selinux-firewall.bats"
	@echo "==> Saving VM test evidence..."
	cd linux/vm && vagrant ssh -c "sudo bats /vagrant/tests/vm/selinux-firewall.bats" \
		> docs/evidence/phase1-vm-test-output.txt 2>&1 || true
	@echo "==> VM tests complete. Evidence: docs/evidence/phase1-vm-test-output.txt"

## help: Show this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
