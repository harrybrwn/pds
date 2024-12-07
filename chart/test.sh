#!/usr/bin/bash

set -eu -o pipefail -o errtrace
shopt -s extdebug

function cleanup() {
  c=$?
  fn="$1"
  if [ $c -eq 0 ]; then
    echo "Pass"
  else
    echo "Failed in '${fn}', exit code: $c"
  fi
}
trap 'cleanup ${FUNCNAME:-__root}' ERR

blob="$(helm template . -f test-values.yml --set config.hostname='x-test.local')"

envs="$(yq <<< $blob 'select(.kind == "Deployment")
  .spec
  .template
  .spec
  .containers[0].env[] 
  | {(.name): {"value": .value, "valueFrom": .valueFrom.secretKeyRef } }
')"

[[ "https://bsky.network" == "$(yq <<< $envs '.PDS_CRAWLERS.value')" ]]
[[ 'tcp://redis:6767' == "$(yq <<< $envs '.PDS_REDIS_SCRATCH_ADDRESS.value' )" ]]
[[ "$(yq <<<$envs '.PDS_REDIS_SCRATCH_PASSWORD.valueFrom.key')" == "pds-redis-password" ]]
[[ "x-test.local" == $(yq <<< $envs '.PDS_HOSTNAME.value') ]]
[[ "/pds" == $(yq <<< $envs '.PDS_DATA_DIRECTORY.value') ]]
[[ "pds-admin@example.com" == $(yq <<< $envs '.PDS_EMAIL_FROM_ADDRESS.value') ]]
[[ "pds-email" == $(yq <<< $envs '.PDS_EMAIL_SMTP_URL.valueFrom.name') ]]
[[ "pds-email-url" == $(yq <<< $envs '.PDS_EMAIL_SMTP_URL.valueFrom.key') ]]

s3="$(yq <<< $blob 'select(.kind == "Deployment")
  .spec
  .template
  .spec
  .containers[0].env[] 
  | select(.name | test("^PDS_BLOBSTORE_S3.*"))
  | {(.name): {"value": .value, "valueFrom": .valueFrom.secretKeyRef } }
')"
[[ "pds-blobs" == $(yq <<<$s3 '.PDS_BLOBSTORE_S3_BUCKET.value') ]]
[[ "us-east-1" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_REGION.value') ]]
[[ "http://minio:9000" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_ENDPOINT.value') ]]
[[ "true" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_FORCE_PATH_STYLE.value') ]]
[[ "pds-s3-id" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_ACCESS_KEY_ID.valueFrom.key') ]]
[[ "pds-s3-secret-key" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_SECRET_ACCESS_KEY.valueFrom.key') ]]
[[ "23000" == $(yq <<< $s3 '.PDS_BLOBSTORE_S3_UPLOAD_TIMEOUT_MS.value') ]]

echo "Ok"
