#!/usr/bin/env bash
# restart-trap-demo.sh - reproduces the "downloaded the fix, still vulnerable" moment on your own machine.
# 1) the legacy container runs 8.4.26, 2) the patched image is pulled (on disk), 3) the check still says VULNERABLE
# because the running process never changed, 4) the container is recreated from the patched image, 5) the check says PATCHED.
# Exits non-zero if any step does not behave as described, so CI can prove it.
set -euo pipefail
cd "$(dirname "$0")/.."
probe=http://127.0.0.1:8081/runtime.php
wait_up() { for _ in $(seq 1 30); do curl -fsS --max-time 2 "$probe" >/dev/null 2>&1 && return 0; sleep 1; done; echo "legacy did not come up" >&2; return 1; }

echo "== 1. legacy is running the pre-fix build"
docker compose up -d legacy >/dev/null; wait_up
if ./php2shell-check.sh "$probe"; then echo "expected VULNERABLE before the update" >&2; exit 1; fi

echo; echo "== 2. download the patched build (it is now on disk)"
LEGACY_TAG=8.4.27-apache docker compose pull -q legacy
echo "patched image downloaded"

echo; echo "== 3. check again without restarting: the old process is still answering"
if ./php2shell-check.sh "$probe"; then echo "expected VULNERABLE: nothing restarted yet" >&2; exit 1; fi

echo; echo "== 4. restart: recreate the container from the patched image"
LEGACY_TAG=8.4.27-apache docker compose up -d legacy >/dev/null; sleep 2; wait_up

echo; echo "== 5. check again"
./php2shell-check.sh "$probe" || { echo "expected PATCHED after the restart" >&2; exit 1; }
echo; echo "A download only changes what's on disk. The restart is what changes what's running."
