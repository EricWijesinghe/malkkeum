#!/usr/bin/env bash
# Publishes the installer and Korean guides to the PUBLIC delivery repo. Never source code.
#   branch beta -> beta channel: every release (vX.Y.Z and vX.Y.Z-beta.N) lands here
#   branch main -> stable channel: only releases without a prerelease suffix
# Needs the write-enabled deploy key via ssh-agent or GIT_SSH_COMMAND (see .github/workflows/release.yml).
#   Env: DIST_REPO (owner/repo), VER (git tag, e.g. v1.0.0), IMAGE_REPO (ghcr.io/owner),
#        SIGNER_REPO (owner/repo whose release.yml signs the images), ASSET_DIR (optional: gets the
#        tag's install.sh + SHA256SUMS for the GitHub Release in DIST_REPO)
set -euo pipefail

: "${DIST_REPO:?set DIST_REPO}" "${VER:?set VER}" "${IMAGE_REPO:?set IMAGE_REPO}" "${SIGNER_REPO:?set SIGNER_REPO}"
src=$(cd "$(dirname "$0")/.." && pwd)
ver=${VER#v}
work=$(mktemp -d)
GUIDE_01="docs/guide/01-서버-설치.md"

# The client-facing install line must point at this delivery repo's newest stable release asset.
LATEST="https://github.com/$DIST_REPO/releases/latest/download/install.sh"
grep -qF "$LATEST" "$src/$GUIDE_01" || { echo "::error::$GUIDE_01 does not mention $LATEST" >&2; exit 1; }

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
         -e "s|^SIGNER_REPO_DEFAULT=.*|SIGNER_REPO_DEFAULT=$SIGNER_REPO|" \
         -e "s|^DEFAULT_CHANNEL=stable\$|DEFAULT_CHANNEL=$channel|" install.sh
  grep -q "^IMAGE_REPO_DEFAULT=$IMAGE_REPO\$" install.sh
  grep -q "^SIGNER_REPO_DEFAULT=$SIGNER_REPO\$" install.sh
  grep -q "^DEFAULT_CHANNEL=$channel\$" install.sh
  bash -n install.sh

  cp -r "$src/docs/guide" "$src/docs/store" .
  sed -e "s|INSTALL_URL|https://github.com/$DIST_REPO/releases/download/$VER/install.sh|g" \
      -e "s|SUMS_URL|https://github.com/$DIST_REPO/releases/download/$VER/SHA256SUMS|g" "$src/docs/delivery-README.md" > README.md
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

# Release assets: the installer of this tag's channel (the branch published last) and its checksum.
if [ -n "${ASSET_DIR:-}" ]; then
  mkdir -p "$ASSET_DIR"
  cp install.sh "$ASSET_DIR/install.sh"
  (cd "$ASSET_DIR" && sha256sum install.sh > SHA256SUMS)
  echo "assets: $ASSET_DIR/install.sh $(cut -d' ' -f1 "$ASSET_DIR/SHA256SUMS")"
fi
