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

gl=${GITLEAKS_CONFIG:-../xo-publish-tools/gitleaks.toml}
if [ -f "$gl" ]; then
  cfgdir=$(mktemp -d "${TMPDIR:-/tmp}/gitleaks-openai.XXXXXX")
  mkdir "$cfgdir/tree"
  git ls-files -co --exclude-standard | rsync -a --files-from=- . "$cfgdir/tree/"
  if ! gitleaks git --no-banner -c "$gl" . >/dev/null 2>&1 || ! (cd "$cfgdir/tree" && gitleaks dir --no-banner -c "$gl" . >/dev/null 2>&1); then
    echo "check-public: gitleaks found leaks (run: gitleaks git -c $gl . and gitleaks dir over the tracked files)" >&2
    fail=1
  fi
  rm -rf "$cfgdir"
else
  echo "check-public: no gitleaks config at $gl; set GITLEAKS_CONFIG" >&2
  fail=1
fi

[ $fail -eq 0 ] && echo "check-public: ok"
exit $fail
