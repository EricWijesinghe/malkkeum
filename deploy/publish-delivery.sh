#!/usr/bin/env bash
# Publishes the installer and Korean guides to the PUBLIC delivery repo. Never source code.
#   branch beta -> beta channel: every release (vX.Y.Z and vX.Y.Z-beta.N) lands here
#   branch main -> stable channel: only releases without a prerelease suffix
#   tag VER     -> annotated, immutable: the commit of this release's own channel branch (main for a
#                  stable release, beta for a prerelease). Its install.sh + SHA256SUMS are what the
#                  pinned install line raw.githubusercontent.com/<DIST_REPO>/<VER>/install.sh downloads.
# Only the write-enabled deploy key is used (ssh-agent or GIT_SSH_COMMAND, see .github/workflows/release.yml).
#   Env: DIST_REPO (owner/repo), VER (git tag, e.g. v1.0.0), IMAGE_REPO (ghcr.io/owner),
#        SIGNER_REPO (owner/repo whose release.yml signs the images), DIST_URL (optional clone URL; tests use a local repo)
#   Release only (SIGN_RELEASE=1): SHA256SUMS gets a cosign bundle, installer_manifest.json an ed25519
#        signature (MANIFEST_KEY_FILE, private PEM); the signed files and the install page are copied to ASSET_DIR.
#        A re-run of a release already on the branch keeps its signatures, so the commit and the tag are unchanged.
set -euo pipefail

: "${DIST_REPO:?set DIST_REPO}" "${VER:?set VER}" "${IMAGE_REPO:?set IMAGE_REPO}" "${SIGNER_REPO:?set SIGNER_REPO}"
src=$(cd "$(dirname "$0")/.." && pwd)
ver=${VER#v}
work=$(mktemp -d)
GUIDE_01="docs/guide/01-서버-설치.md"
RAW="https://raw.githubusercontent.com/$DIST_REPO"
# The guides write the install line as the token INSTALL_URL; each published copy gets its channel's URL.
URL_TOKEN=INSTALL_URL
# Developer-only guide (builds from the private source on a dev PC): never shipped to clients.
DEV_ONLY_GUIDE=05-demo-install.md
GIT_ID=(-c user.name=release -c user.email=release@users.noreply.github.com)

# Branch copies carry the stable-branch line; the tagged branch's copies get the pinned tag line instead.
grep -qF "curl -fsSL $URL_TOKEN | sudo bash" "$src/$GUIDE_01" \
  || { echo "::error::$GUIDE_01 does not carry the install line 'curl -fsSL $URL_TOKEN | sudo bash'" >&2; exit 1; }

case "$ver" in *-*) tag_branch=beta ;; *) tag_branch=main ;; esac

git clone -q "${DIST_URL:-git@github.com:$DIST_REPO.git}" "$work/dist"
cd "$work/dist"

# sign_release <branch>: signs SHA256SUMS and the manifest, or keeps the signatures a previous run published
# for the same files and version. A new cosign bundle changes the commit, and the tag would then refuse to move.
sign_release() {
  local branch="$1" f same=0
  [ "$(git show "origin/$branch:VERSION" 2>/dev/null || true)" = "$ver" ] || same=1
  [ "$(git show "origin/$branch:SHA256SUMS" 2>/dev/null || true)" = "$(cat SHA256SUMS)" ] || same=1
  for f in SHA256SUMS.bundle installer_manifest.json installer_manifest.json.sig; do
    git cat-file -e "origin/$branch:$f" 2>/dev/null || same=1
  done
  if [ "$same" = 0 ]; then
    git checkout -q "origin/$branch" -- SHA256SUMS.bundle installer_manifest.json installer_manifest.json.sig
    echo "$branch: release already signed, keeping its signatures"
    return 0
  fi
  bash "$src/scripts/release/make-manifest.sh" "$VER" . "${MANIFEST_KEY_FILE:?set MANIFEST_KEY_FILE}"
  bash "$src/scripts/release/sign-blob.sh" SHA256SUMS
}

publish() { # publish 브랜치 채널
  local branch="$1" channel="$2" ref="$1"
  [ "$branch" = "$tag_branch" ] && ref=$VER # install lines on the tagged commit point at the tag itself
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
  files=(install.sh)
  if [ -f "$src/deploy/agent.sh" ]; then cp "$src/deploy/agent.sh" agent.sh; files+=(agent.sh); fi
  sha256sum "${files[@]}" > SHA256SUMS
  if [ "${SIGN_RELEASE:-0}" = 1 ]; then sign_release "$branch"; fi

  cp -r "$src/docs/guide" "$src/docs/store" .
  rm -f "guide/$DEV_ONLY_GUIDE"
  # Its row in the guide index goes; other mentions lose the link (the sentence stays).
  sed -i -e "/^| *[0-9][0-9]* *| *\[[^]]*\]($DEV_ONLY_GUIDE)/d" -e "s| *(\[[^]]*\]($DEV_ONLY_GUIDE))||g" -e "s|\[\([^]]*\)\]($DEV_ONLY_GUIDE)|\1|g" guide/*.md
  local guide_url="$RAW/main/install.sh"
  [ "$ref" = "$VER" ] && guide_url="$RAW/$VER/install.sh"
  sed -i "s|$URL_TOKEN|$guide_url|g" guide/*.md
  if grep -rqF "$URL_TOKEN" guide; then echo "::error::unreplaced $URL_TOKEN in guide/" >&2; exit 1; fi
  sed -e "s|INSTALL_URL|$RAW/$ref/install.sh|g" -e "s|SUMS_URL|$RAW/$ref/SHA256SUMS|g" \
      -e "s|BRANCH_URL|$RAW/$branch/install.sh|g" \
      "$src/docs/delivery-README.md" > README.md
  printf '%s\n' "$channel" > CHANNEL
  printf '%s\n' "$ver" > VERSION

  git add -A
  if git diff --cached --quiet; then
    echo "$branch: nothing new"
  else
    git "${GIT_ID[@]}" commit -qm "$channel $ver"
    git push -q origin "$branch"
    echo "$branch: published $channel $ver"
  fi
}

publish beta beta
[ "$tag_branch" = main ] && publish main stable

# Annotated tag on the release's channel commit. A tag is never moved: a re-run with the same commit is a
# no-op, a different commit is an error.
git checkout -q "$tag_branch"
commit=$(git rev-parse HEAD)
remote=$(git ls-remote origin "refs/tags/$VER^{}" | cut -f1)
if [ -n "$remote" ]; then
  [ "$remote" = "$commit" ] \
    || { echo "::error::tag $VER already exists in $DIST_REPO at $remote (wanted $commit); tags are never moved" >&2; exit 1; }
  echo "tag $VER: already published at $commit"
else
  git "${GIT_ID[@]}" tag -a "$VER" -m "다해 $VER ($tag_branch)" "$commit"
  git push -q origin "refs/tags/$VER"
  echo "tag $VER: $commit, install.sh sha256 $(cut -d' ' -f1 SHA256SUMS)"
fi

if [ "${SIGN_RELEASE:-0}" = 1 ]; then # the release assets: the tagged installer, its signed files and the install page
  : "${ASSET_DIR:?set ASSET_DIR for the release assets}"
  mkdir -p "$ASSET_DIR"
  cp install.sh SHA256SUMS SHA256SUMS.bundle installer_manifest.json installer_manifest.json.sig "$ASSET_DIR/"
  bash "$src/scripts/release/build-install-page.sh" install.sh "$RAW/$VER/install.sh" "$work/page"
  cp "$work/page/index.html" "$ASSET_DIR/dahae-install-page.html"
  bash "$src/scripts/release/sign-blob.sh" "$ASSET_DIR/dahae-install-page.html"
fi
