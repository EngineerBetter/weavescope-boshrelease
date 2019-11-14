#!/usr/bin/env bash

set -eu

export ROOT_PATH=$PWD

VERSION=$(cat version/number)
git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

pushd weave-scope-release
  cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    access_key_id: "$BLOBSTORE_ACCESS_KEY_ID"
    secret_access_key: "$BLOBSTORE_SECRET_ACCESS_KEY"
EOF

  bosh create-release \
    --final \
    --version="${VERSION}" \
    "--tarball=../final-release/weave-scope-final-release-${VERSION}.tgz"

  tag_name="v${VERSION}"
  tag_annotation="Final release ${VERSION} tagged via concourse"
  git tag -a "${tag_name}" -m "${tag_annotation}"
  git add -A
  git status

  git commit -m "Adding final release $VERSION via concourse"
popd

git clone weave-scope-release final-weave-scope-release
