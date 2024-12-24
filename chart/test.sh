#!/usr/bin/bash

set -eu -o pipefail -o errtrace
shopt -s extdebug

if [ "${1:-}" = "-v" ]; then
  set -x
fi

function cleanup() {
  c=$?
  fn="$1"
  if [ $c -eq 0 ]; then
    echo "Pass"
  else
    echo "Failed in '${fn}', exit code: $c"
  fi
}
trap 'cleanup ${FUNCNAME:-__root}' EXIT

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
[[ "/pds-data" == $(yq <<< $envs '.PDS_DATA_DIRECTORY.value') ]]
[[ "pds-admin@example.com" == $(yq <<< $envs '.PDS_EMAIL_FROM_ADDRESS.value') ]]
[[ "pds-email" == $(yq <<< $envs '.PDS_EMAIL_SMTP_URL.valueFrom.name') ]]
[[ "pds-email-url" == $(yq <<< $envs '.PDS_EMAIL_SMTP_URL.valueFrom.key') ]]
[[ "https://plc.directory" == $(yq <<< $envs '.PDS_DID_PLC_URL.value') ]]
[[ "https://api.bsky.app" == $(yq <<< $envs '.PDS_BSKY_APP_VIEW_URL.value') ]]
[[ "did:web:api.bsky.app" == $(yq <<< $envs '.PDS_BSKY_APP_VIEW_DID.value') ]]
[[ "https://mod.bsky.app" == $(yq <<< $envs '.PDS_REPORT_SERVICE_URL.value') ]]
[[ "did:plc:ar7c4by46qjdydhdevvrndac" == $(yq <<< $envs '.PDS_REPORT_SERVICE_DID.value') ]]

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

[[
  "this-is-a-bsky-pds" == "$(yq <<< $blob 'select(.kind == "Deployment")
    .spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution
    .nodeSelectorTerms[0].matchExpressions[1].key
  ')"
]]

[[
  "ppcpu69" == "$(yq <<< $blob 'select(.kind == "Deployment")
    .spec.template.spec.tolerations[0].value')"
]]

blob="$(helm template . \
  --set config.hostname='test.localhost' \
  --set config.dataDirectory='/opt/pds' \
  --set-json config.adminPassword.secretKeyRef='{"name":"pds","key":"admin-pw"}' \
  --set-json config.jwtSecret.secretKeyRef='{"name":"pds","key":"jwt-secret"}' \
  --set-json config.plcRotationKeyK256PrivateKeyHex.secretKeyRef='{"name":"pds","key":"plc-rotation-key"}'
)"

[[
  "/opt/pds/blobs" == "$(yq <<< $blob 'select(.kind == "Deployment")
    .spec.template.spec.containers[0].env[]
    | select(.name == "PDS_BLOBSTORE_DISK_LOCATION").value
  ')"
]]


failed() {
  if [ $1 -eq 0 ]; then
    echo "Error: expected failure, line '$2'"
    exit 1
  fi
}

set +e
blob="$(helm template . \
  --set config.hostname='test.localhost'                                   \
  --set config.dataDirectory='/opt/pds'                                    \
  --set config.adminPassword.secretKeyRef.key=admin-pw                     \
  --set config.jwtSecret.secretKeyRef.key=jwt \
  --set config.plcRotationKeyK256PrivateKeyHex.secretKeyRef.key=plc-rot-pk \
  --set config.blobstore.s3.bucket=test-bucket         \
  --set config.blobstore.s3.region=us-east-2           \
  --set config.blobstore.disk.location=/tmp/pds-blobs 2>&1
)"

failed $? $LINENO
blob="$(helm template . \
  --set config.hostname='test.localhost'                                   \
  --set config.dataDirectory='/opt/pds'                                    \
  --set config.adminPassword.secretKeyRef.key=admin-pw                     \
  --set config.jwtSecret.secretKeyRef.key=jwt                              \
  --set config.plcRotationKeyK256PrivateKeyHex.secretKeyRef.key=plc-rot-pk \
  --set config.plcRotationKeyKmsKeyId.secretKeyRef.key=plc-kms-key         \
  --set config.blobstore.s3.bucket=test-bucket         \
  --set config.blobstore.s3.region=us-east-2           \
  --set config.blobstore.disk.location=/tmp/pds-blobs 2>&1
)"

failed $? $LINENO
blob="$(helm template . \
  --set config.hostname='test.yeeyee'                  \
  --set config.dataDirectory='/opt/pds'                \
  --set config.jwtSecret.secretKeyRef.key=jwt          \
  --set config.plcRotationKeyK256PrivateKeyHex.secretKeyRef.key=plc-rot-pk \
  2>/dev/null
)"

failed $? $LINENO
blob="$(helm template . \
  --set config.hostname='test.yeeyee'                  \
  --set config.dataDirectory='/opt/pds'                \
  --set config.adminPassword.secretKeyRef.key=admin-pw \
  --set config.plcRotationKeyK256PrivateKeyHex.secretKeyRef.key=plc-rot-pk \
  2>/dev/null
)"

failed $? $LINENO
blob="$(helm template . \
  --set config.hostname='test.yeeyee'                  \
  --set config.dataDirectory='/opt/pds'                \
  --set config.adminPassword.secretKeyRef.key=admin-pw \
  --set config.jwtSecret.secretKeyRef.key=jwt          \
  2>/dev/null
)"
failed $? $LINENO

set -e

blob="$(helm template . \
  -n 'pds-test' \
  --set config.hostname='test.yeeyee'                   \
  --set config.dataDirectory='/opt/pds'                 \
  --set config.adminPassword.secretKeyRef.key=admin-pw  \
  --set config.jwtSecret.secretKeyRef.key=jwt           \
  --set config.plcRotationKeyK256PrivateKeyHex.secretKeyRef.key=plc-rot-pk \
  --set config.blobstore.disk.location=/tmp/pds-blobs   \
  --set config.resolverTimeout=69                       \
  --set certificate.issuerRef.name=ca-issuer            \
  --set certificate.secretName=test-tls-secret          \
  --set certificate.secretTemplate.annotations.test=123 \
  --set traefikIngress.enabled=true \
  --set traefikIngress.namespace=x
)"
envs="$(yq <<< $blob 'select(.kind == "Deployment")
  .spec.template.spec.containers[0].env[]
  | { (.name): {"value": .value, "valueFrom": .valueFrom.secretKeyRef } }
')"
[[ "test.yeeyee" == "$(yq<<<$envs '.PDS_HOSTNAME.value')" ]]
[[ "69" == "$(yq<<<$envs '.PDS_ID_RESOLVER_TIMEOUT.value')" ]]
[[ "test.yeeyee"   == "$(yq<<<$blob 'select(.kind == "Certificate").spec.commonName')"  ]]
[[ "test.yeeyee"   == "$(yq<<<$blob 'select(.kind == "Certificate").spec.dnsNames[0]')" ]]
[[ "*.test.yeeyee" == "$(yq<<<$blob 'select(.kind == "Certificate").spec.dnsNames[1]')" ]]
[[ "ca-issuer" == "$(yq<<<$blob 'select(.kind == "Certificate").spec.issuerRef.name')"  ]]
[[
  "Host(\`test.yeeyee\`) || HostRegexp(\`^[a-zA-Z0-9_-]{1,255}\.test\.yeeyee$\`)" == "$(
    yq<<<$blob 'select(.kind == "IngressRoute").spec.routes[0].match'
  )"
]]
[[ "test-tls-secret" == "$(yq<<<$blob 'select(.kind == "IngressRoute").spec.tls.secretName')" ]]
[[ "x" == "$(yq<<<$blob 'select(.kind == "IngressRoute").metadata.namespace')" ]]
[[ '123' == "$(yq <<< $blob 'select(.kind == "Certificate").spec.secretTemplate.annotations.test')" ]] 
