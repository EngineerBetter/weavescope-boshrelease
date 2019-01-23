#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

VERSION=$(cat version/number)

cd weave-scope-release

bosh create-release \
  --final \
  "--tarball=../final-release/weave-scope-final-release-${VERSION}.tgz"
