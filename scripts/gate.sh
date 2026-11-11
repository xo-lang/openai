#!/bin/sh
# The checks before a push: format, type check, tests, check-public.
# Usage: XO_CLI=path/to/xo [XO_GATE_NO_PUBLIC=1] scripts/gate.sh
set -eu
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
for m in . azure; do
  (cd "$m" && "$xo" fmt --check . && "$xo" check . && "$xo" test .)
done
# XO_GATE_NO_PUBLIC=1: not check-public (it needs ../xo-publish-tools and
# gitleaks, a push's checks): the lead's daily run of every SDK gate on
# an offload host from a fresh clone (scripts/lead/sdk-daily.sh in xo)
[ "${XO_GATE_NO_PUBLIC:-}" = 1 ] || sh scripts/check-public.sh
echo "gate: ok"
