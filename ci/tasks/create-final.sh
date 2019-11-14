#!/usr/bin/env bash

set -eu

export ROOT_PATH=$PWD

VERSION=$(cat version/number)

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
    "--tarball=../final-release/weave-scope-final-release-${VERSION}.tgz"
popd

mv weave-scope-release updated-weave-scope-release
