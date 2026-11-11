#!/bin/sh
# Rehearses the release with no network write: clones HEAD into a scratch
# directory with a bare "remote", tags the root (vX) and azure (azure/vX)
# there, pushes the tags to that remote, then type checks both modules
# from the tagged clone with no workspace (after `xo mod tidy`, which must
# leave each xo.mod as it is) and an app that gets both with `xo get`.
# github.com/xo-lang/azure is fetched from AZURE_REPO (a local clone with
# its v0.1.0 tag) when it is set, else from GitHub.
# Usage: XO_CLI=/path/to/xo [AZURE_REPO=dir] scripts/check-release.sh v0.1.0 [scratch dir]
set -eu
cd "$(dirname "$0")/.."
v=${1:?usage: check-release.sh v0.1.0 [scratch dir]}
xo=${XO_CLI:-xo}
work=${2:-$(mktemp -d)}
mkdir -p "$work"
src=$(pwd)
[ -d "$work/modcache" ] && chmod -R u+w "$work/modcache"
rm -rf "$work/remote.git" "$work/clone" "$work/app" "$work/modcache"
git clone -q --bare "$src" "$work/remote.git"
git clone -q "$work/remote.git" "$work/clone"
(cd "$work/clone" && for t in "$v" "azure/$v"; do GIT_COMMITTER_NAME=release-check GIT_COMMITTER_EMAIL=release-check@invalid git tag -a "$t" -m "$t"; done && git push -q origin "$v" "azure/$v")
rw="github.com/xo-lang/openai=$work/remote.git"
[ -n "${AZURE_REPO-}" ] && rw="$rw,github.com/xo-lang/azure=$AZURE_REPO"
export XO_GIT_REWRITE="$rw"
export XO_MODCACHE="$work/modcache"
rm -f "$work/clone/xo.work"
fails=0
for m in . azure; do
  d="$work/clone/$m"
  if ! (cd "$d" && "$xo" mod tidy > "$work/check.out" 2>&1 && git diff --quiet -- xo.mod && "$xo" check --workspace=off . >> "$work/check.out" 2>&1); then
    echo "check-release: FAIL $m"
    (cd "$d" && git diff -- xo.mod) | sed 's/^/  /'
    tail -5 "$work/check.out" | sed 's/^/  /'
    fails=$((fails + 1))
  fi
done
echo "check-release: 2 modules checked with no workspace, $fails failed"
mkdir -p "$work/app"
cd "$work/app"
printf 'module example.com/app\nedition preview\n' > xo.mod
cat > main.xo <<'XO'
use github.com/xo-lang/openai
use github.com/xo-lang/openai/azure

fn main(os: Os) {
  os.stdio.println("${openai.PACKAGE_VERSION} ${azure.TOKEN_USER_AGENT}")
}
XO
"$xo" get github.com/xo-lang/openai@"$v" github.com/xo-lang/openai/azure@"$v" > "$work/get.out" 2>&1 || { echo "check-release: FAIL xo get"; tail -5 "$work/get.out"; exit 1; }
"$xo" check --workspace=off . > "$work/app.out" 2>&1 || { echo "check-release: FAIL app"; tail -5 "$work/app.out"; exit 1; }
echo "check-release: an app got openai and openai/azure at $v and checks"
[ $fails -eq 0 ]
