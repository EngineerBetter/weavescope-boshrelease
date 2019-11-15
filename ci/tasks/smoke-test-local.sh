#!/usr/bin/env bash

set -eux

export BOSH_NON_INTERACTIVE=true

start-bosh

source /tmp/local-bosh/director/env

bosh upload-stemcell --sha1 1a18280689eb6b4a459c7924a16cbf9a7ca76043 \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=621.5

pushd candidate-release
  bosh upload-release weave-scope-dev-release.tgz
popd

# Add and test weave scope app
pushd weave-scope-release
  bosh -d weave-scope deploy ci/manifests/scope-app.yml

  # Check that weave scope app has been deployed
  SCOPE_HOST="$(bosh -d weave-scope instances | grep running | awk '{ print $4 }')"
  curl -L "${SCOPE_HOST}:4040" | grep "<title>Weave Scope</title>"

  bosh update-runtime-config --name bosh-dns ci/manifests/dns-runtime-config.yml
  bosh update-runtime-config manifests/bosh-lite/runtime-config.yml \
    --var plugin_root="/var/vcap/data/scope/plugins" \
    --var atc_password=admin \
    --var atc_username=admin \
    --var version="$(cat .git/short_ref)"
popd

pushd concourse-bosh-deployment/cluster
  bosh deploy -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store /tmp/local-bosh/director/creds.yml \
  -o operations/basic-auth.yml \
  --var local_user.username=admin \
  --var local_user.password=admin \
  --var external_url=http://127.0.0.1:8080 \
  --var network_name=default \
  --var web_vm_type=default \
  --var db_vm_type=default \
  --var db_persistent_disk_type=default \
  --var worker_vm_type=default \
  --var deployment_name=concourse
popd

CONCOURSE_IP=$(bosh -d concourse vms --json | jq '.Tables[0].Rows[] | select(.instance | startswith("web")).ips' -r)

curl -k -o fly  "http://$CONCOURSE_IP:8080/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

./fly -t local login -c "http://$CONCOURSE_IP:8080" -u admin -p admin

# Tests that scope app is receiving reports from probes db/0, web/0, worker/0
curl "${SCOPE_HOST}:4040/api/probes" | jq -re '.[] | select(.hostname=="db/0")'
curl "${SCOPE_HOST}:4040/api/probes" | jq -re '.[] | select(.hostname=="web/0")'
curl "${SCOPE_HOST}:4040/api/probes" | jq -re '.[] | select(.hostname=="worker/0")'

# Test that scope-bosh is correctly picking up garden process

# Check there are no garden processes being monitored
curl "${SCOPE_HOST}:4040/api/topology/processes" | jq -re '[.nodes[] | select( .label=="/var/vcap/packages/guardian/bin/gdn")] | length==0'

./fly -t local set-pipeline -p simple-pipeline -c weave-scope-release/ci/manifests/simple-pipeline.yml
./fly -t local unpause-pipeline -p simple-pipeline
./fly -t local trigger-job -j simple-pipeline/job

# Check there is at least 1 garden process being monitored
curl "${SCOPE_HOST}:4040/api/topology/processes" | jq -re '[.nodes[] | select( .label=="/var/vcap/packages/guardian/bin/gdn")] | length>0'
