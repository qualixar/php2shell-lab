#!/usr/bin/env bash
# php2shell-check.sh <url-of-runtime-probe>
# Asks the web interpreter (not the CLI) which PHP it runs, then compares it with
# the 21 Oct 2026 fixed releases. A distro build may carry a backport under an
# older number: confirm against your vendor's advisory before trusting a FAIL.
set -euo pipefail
url="${1:?usage: php2shell-check.sh http://host/runtime.php}"
json="$(curl -fsS --max-time 10 "$url")"
ver="$(printf '%s' "$json" | sed -n 's/.*"php_version": "\([^"]*\)".*/\1/p')"
sapi="$(printf '%s' "$json" | sed -n 's/.*"sapi": "\([^"]*\)".*/\1/p')"
upl="$(printf '%s' "$json" | sed -n 's/.*"upload_progress": "\([^"]*\)".*/\1/p')"

fixed_for() { case "$1" in 8.5) echo 8.5.12;; 8.4) echo 8.4.27;; 8.3) echo 8.3.36;; 8.2) echo 8.2.35;; *) echo EOL;; esac; }
branch="${ver%.*}"; need="$(fixed_for "$branch")"

printf 'web runtime : PHP %s (%s)\n' "$ver" "$sapi"
if [[ "$need" == EOL ]]; then
  printf 'PHP2Shell   : EOL BRANCH %s - no official release; vendor backport, upgrade, or take it offline\n' "$branch"; status=2
elif [[ "$(printf '%s\n%s\n' "$need" "$ver" | sort -V | head -1)" == "$need" ]]; then
  printf 'PHP2Shell   : PATCHED (>= %s)\n' "$need"; status=0
else
  printf 'PHP2Shell   : VULNERABLE (needs %s)\n' "$need"; status=1
fi
printf 'upload prog : %s %s\n' "$upl" "$([[ $upl == off ]] && echo '(CVE-2026-115560 interim setting applied)' || echo '(set session.upload_progress.enabled=0 until the next release)')"
exit "$status"
