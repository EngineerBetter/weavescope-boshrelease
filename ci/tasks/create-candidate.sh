#!/usr/bin/env bash

set -eux

VERSION=$(cat .git/short_ref)

bosh create-release --tarball=../candidate-release/weave-scope-dev-release.tgz --force --version="${VERSION}"
