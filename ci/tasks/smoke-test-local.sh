#!/usr/bin/env bash

set -eux

export BOSH_NON_INTERACTIVE=true

start-bosh

source /tmp/local-bosh/director/env

bosh upload-stemcell --sha1 1a18280689eb6b4a459c7924a16cbf9a7ca76043 \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=621.5

cd candidate-release
bosh upload-release weave-scope-dev-release.tgz

# Add and test weave scope app
cd ../weave-scope-release
bosh -d weave-scope deploy \
  "$PWD/ci/manifests/scope-app.yml"

# Check that weave scope app has been deployed
SCOPE_HOST="$(bosh -d weave-scope instances | grep running | awk '{ print $4 }')"
curl -L "${SCOPE_HOST}:4040" | grep "<title>Weave Scope</title>"

cd ../concourse-bosh-deployment/cluster
bosh deploy -d concourse concourse.yml \
 -l ../versions.yml \
 --vars-store cluster-creds.yml \
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

CONCOURSE_IP=$(bosh -d concourse vms --json | jq '.Tables[0].Rows[] | select(.instance | startswith("web")).ips' -r)

curl -k -o fly  "http://$CONCOURSE_IP:8080/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

./fly -t local login -c "http://$CONCOURSE_IP:8080" -u admin -p admin
