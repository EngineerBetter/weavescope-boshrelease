#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

cd weave-scope-release

bosh create-release --tarball=../release/weave-scope-dev-release.tgz --timestamp-version --force
