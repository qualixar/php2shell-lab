#!/usr/bin/env bash
# parse-test.sh - offline tests for php2shell-check.sh against canned probe outputs (no containers needed).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
t() { # name, json, expected exit, expected substring
  printf '%s' "$2" > "$tmp/p.json"
  out="$(./php2shell-check.sh "file://$tmp/p.json" 2>&1)"; rc=$?
  if [[ $rc -eq $3 && "$out" == *"$4"* ]]; then echo "ok   $1"; else echo "FAIL $1 (rc=$rc)"; echo "$out"; fail=1; fi
}
t "pretty JSON, vulnerable"        '{ "php_version": "8.4.26", "sapi": "fpm-fcgi", "upload_progress": "on" }' 1 "VULNERABLE (needs 8.4.27)"
t "compact JSON, patched"          '{"php_version":"8.4.27","sapi":"apache2handler","upload_progress":"off"}' 0 "PATCHED"
t "Surý build string, patched"     '{"php_version":"8.4.27-1+ubuntu24.04.1+deb.sury.org+1","sapi":"fpm-fcgi","upload_progress":"off"}' 0 "PATCHED (>= 8.4.27)"
t "Debian build string, vulnerable" '{"php_version":"8.3.35-1~deb12u1","sapi":"fpm-fcgi","upload_progress":"on"}' 1 "needs 8.3.36"
t "8.5 patched"                    '{"php_version":"8.5.12","sapi":"cli-server","upload_progress":"off"}' 0 "PATCHED"
t "EOL branch"                     '{"php_version":"8.1.31","sapi":"fpm-fcgi","upload_progress":"on"}' 2 "EOL BRANCH 8.1"
t "garbage probe"                  'not json' 3 "could not read php_version"
exit $fail
