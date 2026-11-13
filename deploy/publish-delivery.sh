#!/usr/bin/env bash
# Publishes the installer and Korean guides to the PUBLIC delivery repo. Never source code.
#   branch beta -> beta channel: every release (vX.Y.Z and vX.Y.Z-beta.N) lands here
#   branch main -> stable channel: only releases without a prerelease suffix
#   tag VER     -> annotated, immutable: the commit of this release's own channel branch (main for a
#                  stable release, beta for a prerelease). Its install.sh + SHA256SUMS are what the
#                  pinned install line raw.githubusercontent.com/<DIST_REPO>/<VER>/install.sh downloads.
# Only the write-enabled deploy key is used (ssh-agent or GIT_SSH_COMMAND, see .github/workflows/release.yml).
#   Env: DIST_REPO (owner/repo), VER (git tag, e.g. v1.0.0), IMAGE_REPO (ghcr.io/owner),
#        SIGNER_REPO (owner/repo whose release.yml signs the images)
set -euo pipefail

: "${DIST_REPO:?set DIST_REPO}" "${VER:?set VER}" "${IMAGE_REPO:?set IMAGE_REPO}" "${SIGNER_REPO:?set SIGNER_REPO}"
src=$(cd "$(dirname "$0")/.." && pwd)
ver=${VER#v}
work=$(mktemp -d)
GUIDE_01="docs/guide/01-서버-설치.md"
RAW="https://raw.githubusercontent.com/$DIST_REPO"
# The guides are written against this delivery repo; copies get DIST_REPO instead.
DOC_REPO=EricWijesinghe/malkkeum-install
# Developer-only guide (builds from the private source on a dev PC): never shipped to clients.
DEV_ONLY_GUIDE=05-demo-install.md
GIT_ID=(-c user.name=release -c user.email=release@users.noreply.github.com)

# The guides carry the stable-branch line; the tagged branch's copies get the pinned tag line instead.
grep -qF "https://raw.githubusercontent.com/$DOC_REPO/main/install.sh" "$src/$GUIDE_01" \
  || { echo "::error::$GUIDE_01 does not mention https://raw.githubusercontent.com/$DOC_REPO/main/install.sh" >&2; exit 1; }

case "$ver" in *-*) tag_branch=beta ;; *) tag_branch=main ;; esac

git clone -q "git@github.com:$DIST_REPO.git" "$work/dist"
cd "$work/dist"

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
  sha256sum install.sh > SHA256SUMS

  cp -r "$src/docs/guide" "$src/docs/store" .
  rm -f "guide/$DEV_ONLY_GUIDE"
  # Its row in the guide index goes; other mentions lose the link (the sentence stays).
  sed -i -e "/^| *[0-9][0-9]* *| *\[[^]]*\]($DEV_ONLY_GUIDE)/d" -e "s| *(\[[^]]*\]($DEV_ONLY_GUIDE))||g" -e "s|\[\([^]]*\)\]($DEV_ONLY_GUIDE)|\1|g" guide/*.md
  sed -i "s|github\.com/$DOC_REPO/|github.com/$DIST_REPO/|g; s|githubusercontent\.com/$DOC_REPO/|githubusercontent.com/$DIST_REPO/|g" guide/*.md
  if [ "$ref" = "$VER" ]; then sed -i "s|$RAW/main/install.sh|$RAW/$VER/install.sh|g" guide/*.md; fi
  sed -e "s|INSTALL_URL|$RAW/$ref/install.sh|g" -e "s|SUMS_URL|$RAW/$ref/SHA256SUMS|g" \
      -e "s|BRANCH_URL|$RAW/$branch/install.sh|g" -e "s|githubusercontent\.com/$DOC_REPO/|githubusercontent.com/$DIST_REPO/|g" \
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
