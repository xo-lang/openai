#!/bin/sh
# The checks before a push: format, type check, tests, check-public.
# Usage: XO_CLI=path/to/xo scripts/gate.sh
set -eu
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
for m in . azure; do
  (cd "$m" && "$xo" fmt --check . && "$xo" check . && "$xo" test .)
done
sh scripts/check-public.sh
echo "gate: ok"
