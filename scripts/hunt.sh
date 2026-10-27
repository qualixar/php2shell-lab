#!/usr/bin/env bash
# hunt.sh [service] [since] - read-only first look at a PHP host that ran a vulnerable build. Changes nothing.
# Patched is not the same as clean: these are starting points, not proof either way.
#   service  docker compose service to inspect (default: legacy). HOST=1 runs the same checks on this machine.
#   since    first date to look back to (default: 2026-10-17, the earliest reported attempt)
# Optional env: WEBROOT, ACCESS_LOG (current access log; rotated *.1 / *.gz next to it are read too),
#               WEB_USERS (default "www-data apache nginx daemon http"), SESSION_DIR (default: PHP's session.save_path)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
svc="${1:-legacy}"; since="${2:-2026-10-17}"
run() { if [[ "${HOST:-0}" == 1 ]]; then sh -c "$1"; else docker compose exec -T "$svc" sh -c "$1"; fi; }
webroot="${WEBROOT:-/var/www/html}"; log="${ACCESS_LOG:-logs/$svc/access.log}"
users="${WEB_USERS:-www-data apache nginx daemon http}"

echo "== files in the web root changed since $since"
run "find '$webroot' -newermt '$since' -type f 2>/dev/null" || true

echo; echo "== POST requests in the access log, rotated logs included ($log*)"
echo "   (front controllers route /login or /wp-json/... to index.php, so this counts every POST, not just *.php URIs)"
total=0
for f in "$log" "$log".1 "$log".*.gz; do
  [[ -f "$f" ]] || continue
  n=$(zgrep -c '"POST ' "$f" 2>/dev/null || true); n=${n:-0}
  echo "   $f: $n"; total=$((total + n))
done
echo "   total: $total"

echo; echo "== PHP session files (session.save_path; on systemd hosts PrivateTmp hides /tmp, and a restart wipes it)"
sess="${SESSION_DIR:-$(run "php -r 'echo session_save_path();' 2>/dev/null" || true)}"
for d in ${sess:-} /var/lib/php/sessions /var/lib/php/session /tmp; do
  run "[ -d '$d' ] && ls -la '$d' 2>/dev/null | grep -c sess_ | sed 's|^|   $d: |'" 2>/dev/null || true
done

echo; echo "== processes running as the web server user that are shells, interpreters or download tools"
pat='^(sh|bash|dash|ash|zsh|python[0-9.]*|perl|ruby|php|nc|ncat|socat|curl|wget)$'
found=0
for u in $users; do
  out=$(run "ps -o pid=,ppid=,user=,comm= -u '$u' 2>/dev/null" | awk -v p="$pat" '$4 ~ p' || true)
  [[ -n "$out" ]] && { echo "$out"; found=1; }
done
[[ $found == 1 ]] || echo "   none seen for users: $users (php-fpm/apache workers themselves are expected and not listed)"

echo; echo "Before you restart a real server, capture worker memory if you may need evidence: a restart destroys it."
