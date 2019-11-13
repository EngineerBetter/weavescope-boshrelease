#!/usr/bin/env bash

set -eux

VERSION=$(cat version/number)

pushd updated-weave-scope-release
  git config --global user.email "ci@localhost"
  git config --global user.name "CI Bot"

  tag_name="v${VERSION}"
  tag_annotation="Final release ${VERSION} tagged via concourse"
  git tag -a "${tag_name}" -m "${tag_annotation}"

  git checkout master
  git status

  cat >> config/private.yml <<EOF
  ---
  blobstore:
    provider: s3
    options:
      access_key_id: "$BLOBSTORE_ACCESS_KEY_ID"
      secret_access_key: "$BLOBSTORE_SECRET_ACCESS_KEY"
EOF

  bosh int \
    manifests/bosh-lite/runtime-config.yml \
    -o ci/tasks/update-runtime-config-version.yml \
    -v version=$VERSION \
    > manifests/bosh-lite/new-runtime-config.yml

  # Can't redirect to file being read
  mv manifests/bosh-lite/new-runtime-config.yml \
      manifests/bosh-lite/runtime-config.yml

  git add -A
  git status

  git commit -m "Adding final release $VERSION via concourse"
popd

git clone updated-weave-scope-release final-weave-scope-release
