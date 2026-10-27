#!/usr/bin/env bash
# hunt.sh [service] [since] - read-only first look for a PHP host that ran a vulnerable build.
# Patched is not the same as clean: these are starting points, not proof either way. It changes nothing.
#   service  docker compose service to inspect (default: legacy). Use HOST=1 to run the same checks on this machine.
#   since    first date to look back to (default: 2026-10-17, the earliest reported attempt)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
svc="${1:-legacy}"; since="${2:-2026-10-17}"
run() { if [[ "${HOST:-0}" == 1 ]]; then sh -c "$1"; else docker compose exec -T "$svc" sh -c "$1"; fi; }
webroot="${WEBROOT:-/var/www/html}"; log="${ACCESS_LOG:-logs/$svc/access.log}"

echo "== files in the web root changed since $since"
run "find '$webroot' -newermt '$since' -type f 2>/dev/null" || true
echo; echo "== POST requests to .php files in the access log ($log)"
grep -c 'POST .*\.php' "$log" 2>/dev/null || echo "0 (or no log at $log)"
echo; echo "== leftover session upload files in /tmp"
run "ls -la /tmp 2>/dev/null | grep sess_ || echo 'no session files'"
echo; echo "== shells or download tools whose parent is the web server"
run "ps -eo user,ppid,comm 2>/dev/null | grep -E ' (sh|bash|curl|wget)\$' || echo 'no shells spawned by the web server'"
echo; echo "Before you restart a real server, capture worker memory if you may need evidence: a restart destroys it."
