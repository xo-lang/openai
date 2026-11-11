#!/bin/sh
# Fails when tracked files hold data that must not be public: GUIDs other
# than the all-zero placeholder, OpenAI and Azure keys, connection strings,
# local home paths, IP addresses outside loopback and the documentation
# ranges, and email addresses outside example.com/org/net. Then runs
# gitleaks over the whole history with the publishing tools' rules.
# Usage: scripts/check-public.sh
set -u
cd "$(dirname "$0")/.."
fail=0
files=$(git ls-files -co --exclude-standard | grep -v -E '^(LICENSE|NOTICE\.md)$')

report() {
  echo "check-public: $1 ($(echo "$2" | grep -c .) lines)" >&2
  echo "$2" | head -20 >&2
  fail=1
}

hits=$(echo "$files" | xargs grep -n -I -i -E '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' 2>/dev/null | grep -v -E '00000000-0000-0000-0000-000000000000')
[ -n "$hits" ] && report "GUIDs (subscription, tenant or client ids?)" "$hits"

# OpenAI keys (sk-..., sk-proj-...), Azure keys and connection strings
hits=$(echo "$files" | xargs grep -n -I -E 'sk-[A-Za-z0-9_-]{20,}|AccountKey=[A-Za-z0-9+/]{20}|SharedAccessKey=[A-Za-z0-9+/]{20}|(^|[?&"])sig=[A-Za-z0-9%+/]{20}' 2>/dev/null)
[ -n "$hits" ] && report "keys, connection strings or signatures" "$hits"

hits=$(echo "$files" | xargs grep -n -I -E '/U''sers/|/h''ome/[a-z]' 2>/dev/null | grep -v '^scripts/check-public.sh:')
[ -n "$hits" ] && report "home paths" "$hits"

# loopback, the RFC 5737 documentation ranges and x.0.0.0 versions are allowed
hits=$(echo "$files" | xargs grep -n -I -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)' 2>/dev/null | grep -v -E '127\.0\.0\.1|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+|0\.0\.0\.0|(^|[^0-9.])[0-9]{1,3}\.0\.0\.0([^0-9.]|$)' | grep -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)')
[ -n "$hits" ] && report "IP addresses" "$hits"

hits=$(echo "$files" | xargs grep -n -I -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' 2>/dev/null | grep -v -E '@example\.(com|org|net)')
[ -n "$hits" ] && report "email addresses" "$hits"

# gitleaks_run WHAT DIR ARGS...: runs gitleaks ARGS in DIR. On a failure
# it says whether gitleaks found leaks or failed to run (both exit 1;
# the "leaks found" line tells them apart), with the last lines of its
# redacted output.
gitleaks_run() {
  what=$1
  dir=$2
  shift 2
  out=$(mktemp "${TMPDIR:-/tmp}/gitleaks-out.XXXXXX")
  (cd "$dir" && gitleaks "$@" --no-banner --no-color --redact -v) >"$out" 2>&1 && { rm -f "$out"; return 0; }
  rc=$?
  if grep -q 'leaks found' "$out"; then
    echo "check-public: gitleaks found leaks in $what:" >&2
  else
    echo "check-public: gitleaks failed on $what (exit $rc):" >&2
  fi
  tail -20 "$out" | sed 's/^/  /' >&2
  rm -f "$out"
  return 1
}

gl=${GITLEAKS_CONFIG:-../xo-publish-tools/gitleaks.toml}
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "check-public: gitleaks is not installed or not on PATH (go install puts it in ~/go/bin); nothing was scanned" >&2
  fail=1
elif [ -f "$gl" ]; then
  # absolute, since the tree scan below runs from another directory
  gl=$(cd "$(dirname "$gl")" && pwd)/$(basename "$gl")
  cfgdir=$(mktemp -d "${TMPDIR:-/tmp}/gitleaks-openai.XXXXXX")
  mkdir "$cfgdir/tree"
  git ls-files -co --exclude-standard | rsync -a --files-from=- . "$cfgdir/tree/"
  gitleaks_run "the git history" . git -c "$gl" . || fail=1
  gitleaks_run "the tracked files" "$cfgdir/tree" dir -c "$gl" . || fail=1
  rm -rf "$cfgdir"
else
  echo "check-public: no gitleaks config at $gl; set GITLEAKS_CONFIG" >&2
  fail=1
fi

[ $fail -eq 0 ] && echo "check-public: ok"
exit $fail
