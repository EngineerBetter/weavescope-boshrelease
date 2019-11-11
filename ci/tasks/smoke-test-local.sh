#!/usr/bin/env bash

set -eux

start-bosh

source /tmp/local-bosh/director/env

bosh upload-stemcell --sha1 1a18280689eb6b4a459c7924a16cbf9a7ca76043 \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=621.5

bosh create-release \
  --dir "$PWD/weave-scope-release/"

bosh upload-release \
  --dir "$PWD/weave-scope-release/"

export BOSH_NON_INTERACTIVE=true

bosh -d scope-app deploy \
  "$PWD/ci/manifests/scope-app.yml"

SCOPE_HOST="$(bosh -d scope-app instances | grep running | awk '{ print $4 }')"
curl -L "${SCOPE_HOST}:4040"

sleep 3600
