#!/usr/bin/env bash
# Publishes the installer and Korean guides to the PUBLIC delivery repo. Never source code.
#   branch beta -> beta channel: every release (vX.Y.Z and vX.Y.Z-beta.N) lands here
#   branch main -> stable channel: only releases without a prerelease suffix
# Needs the write-enabled deploy key via ssh-agent or GIT_SSH_COMMAND (see .github/workflows/release.yml).
#   Env: DIST_REPO (owner/repo), VER (git tag, e.g. v1.0.0), IMAGE_REPO (ghcr.io/owner)
set -euo pipefail

: "${DIST_REPO:?set DIST_REPO}" "${VER:?set VER}" "${IMAGE_REPO:?set IMAGE_REPO}"
src=$(cd "$(dirname "$0")/.." && pwd)
ver=${VER#v}
work=$(mktemp -d)
GUIDE_01="docs/guide/01-서버-설치.md"

# The client-facing install line must point at this delivery repo.
grep -q "raw.githubusercontent.com/$DIST_REPO/main/install.sh" "$src/$GUIDE_01" \
  || { echo "::error::$GUIDE_01 does not mention https://raw.githubusercontent.com/$DIST_REPO/main/install.sh" >&2; exit 1; }

git clone -q "git@github.com:$DIST_REPO.git" "$work/dist"
cd "$work/dist"

publish() { # publish 브랜치 채널
  local branch="$1" channel="$2"
  if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    git checkout -q -B "$branch" "origin/$branch"
  else
    git checkout -q --orphan "$branch"
  fi
  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

  cp "$src/deploy/install.sh" install.sh
  sed -i -e "s|^IMAGE_REPO_DEFAULT=.*|IMAGE_REPO_DEFAULT=$IMAGE_REPO|" \
         -e "s|^DEFAULT_CHANNEL=stable\$|DEFAULT_CHANNEL=$channel|" install.sh
  grep -q "^IMAGE_REPO_DEFAULT=$IMAGE_REPO\$" install.sh
  grep -q "^DEFAULT_CHANNEL=$channel\$" install.sh
  bash -n install.sh

  cp -r "$src/docs/guide" "$src/docs/store" .
  sed "s|INSTALL_URL|https://raw.githubusercontent.com/$DIST_REPO/$branch/install.sh|" "$src/docs/delivery-README.md" > README.md
  printf '%s\n' "$channel" > CHANNEL
  printf '%s\n' "$ver" > VERSION

  git add -A
  if git diff --cached --quiet; then
    echo "$branch: nothing new"
  else
    git -c user.name=release -c user.email=release@users.noreply.github.com commit -qm "$channel $ver"
    git push -q origin "$branch"
    echo "$branch: published $channel $ver"
  fi
}

publish beta beta
case "$ver" in
  *-*) ;;
  *) publish main stable ;;
esac
