# BlueSky Personal Data Server (PDS)

See [the original](https://github.com/bluesky-social/pds/) for more info.

## Install with Helm

Add my repo.

```bash
helm repo add hrry https://helm.hrry.dev
```

Create a secret.

```bash
kubectl create secret generic "pds" \
  --from-literal="admin-pw=$(openssl rand --hex 16)" \
  --from-literal="jwt-secret=$(openssl rand --hex 16)" \
  --from-literal="plc-rotation-key=$(
    openssl ecparam --name secp256k1 --genkey --noout --outform DER \
      | tail --bytes=+8 \
      | head --bytes=32 \
      | xxd --plain --cols 32
  )"
```

Deploy the chart with the generated secrets.

```bash
helm install hrry/pds \
  --set config.hostname='test.localhost' \
  --set config.dataDirectory='/pds' \
  --set-json config.adminPassword.secretKeyRef='{"name":"pds","key":"admin-pw"}' \
  --set-json config.jwtSecret.secretKeyRef='{"name":"pds","key":"jwt-secret"}' \
  --set-json config.plcRotationKeyK256PrivateKeyHex.secretKeyRef='{"name":"pds","key":"plc-rotation-key"}'
```

## Environment Variables

| name                 | type   | env                        | default                   |
| ---                  | ---    | ---                        | ---                       |
| port                 | `int`  | PDS_PORT                   | `3000`                    |
| hostname             | `str`  | PDS_HOSTNAME               | `localhost`               |
| serviceDid           | `str`  | PDS_SERVICE_DID            | `did:web:${PDS_HOSTNAME}` |
| serviceName          | `str`  | PDS_SERVICE_NAME           | |
| version              | `str`  | PDS_VERSION                | |
| homeUrl              | `str`  | PDS_HOME_URL               | |
| logoUrl              | `str`  | PDS_LOGO_URL               | |
| privacyPolicyUrl     | `str`  | PDS_PRIVACY_POLICY_URL     | |
| supportUrl           | `str`  | PDS_SUPPORT_URL            | |
| termsOfServiceUrl    | `str`  | PDS_TERMS_OF_SERVICE_URL   | |
| contactEmailAddress  | `str`  | PDS_CONTACT_EMAIL_ADDRESS  | |
| acceptingRepoImports | `bool` | PDS_ACCEPTING_REPO_IMPORTS | `true`                   |
| blobUploadLimit      | `int`  | PDS_BLOB_UPLOAD_LIMIT      | `5 * 1024 * 1024` // 5mb |
| devMode              | `bool` | PDS_DEV_MODE               | `false` |
| log enabled          | `bool` | LOG_ENABLED                | `false` |
| log level            | `str`  | LOG_LEVEL                  | `info`  |

### branding

| name         | type   | env               |
| ---          | ---    | ---               |
| brandColor   | `str`  | PDS_PRIMARY_COLOR |
| errorColor   | `str`  | PDS_ERROR_COLOR   |
| warningColor | `str`  | PDS_WARNING_COLOR |

### database

| name                     | type   | env                                    | default |
| ---                      | ---    | ---                                    | ---     |
| dataDirectory            | `str`  | PDS_DATA_DIRECTORY                     | |
| accountDbLocation        | `str`  | PDS_ACCOUNT_DB_LOCATION                | `${PDS_DATA_DIRECTORY}/account.sqlite`   |
| sequencerDbLocation      | `str`  | PDS_SEQUENCER_DB_LOCATION              | `${PDS_DATA_DIRECTORY}/sequencer.sqlite` |
| didCacheDbLocation       | `str`  | PDS_DID_CACHE_DB_LOCATION              | `${PDS_DATA_DIRECTORY}/did_cache.sqlite` |
| disableWalAutoCheckpoint | `bool` | PDS_SQLITE_DISABLE_WAL_AUTO_CHECKPOINT | `false` |

### actor store

| name                | type   | env                        | default                        |
| ---                 | ---    | ---                        | ---                            |
| actorStoreDirectory | `str`  | PDS_ACTOR_STORE_DIRECTORY  | `${PDS_DATA_DIRECTORY}/actors` |
| actorStoreCacheSize | `int`  | PDS_ACTOR_STORE_CACHE_SIZE | `100`                          |

### blobstore

Either S3 or disk is required.

| name                       | type   | env                                | default |
| ---                        | ---    | ---                                | ---     |
| blobstoreS3Bucket          | `str`  | PDS_BLOBSTORE_S3_BUCKET            | |
| blobstoreS3Region          | `str`  | PDS_BLOBSTORE_S3_REGION            | |
| blobstoreS3Endpoint        | `str`  | PDS_BLOBSTORE_S3_ENDPOINT          | |
| blobstoreS3ForcePathStyle  | `bool` | PDS_BLOBSTORE_S3_FORCE_PATH_STYLE  | |
| blobstoreS3AccessKeyId     | `str`  | PDS_BLOBSTORE_S3_ACCESS_KEY_ID     | |
| blobstoreS3SecretAccessKey | `str`  | PDS_BLOBSTORE_S3_SECRET_ACCESS_KEY | |
| blobstoreS3UploadTimeoutMs | `int`  | PDS_BLOBSTORE_S3_UPLOAD_TIMEOUT_MS | `20000` |
| blobstoreDiskLocation      | `str`  | PDS_BLOBSTORE_DISK_LOCATION        | |
| blobstoreDiskTmpLocation   | `str`  | PDS_BLOBSTORE_DISK_TMP_LOCATION    | |

### Identity

| name                    | type   | env                             | default                 |
| ---                     | ---    | ---                             | ---                     |
| didPlcUrl               | `str`  | PDS_DID_PLC_URL                 | `https://plc.directory` |
| didCacheStaleTTL        | `int`  | PDS_DID_CACHE_STALE_TTL         | 1 hour    |
| didCacheMaxTTL          | `int`  | PDS_DID_CACHE_MAX_TTL           | 1 day     |
| resolverTimeout         | `int`  | PDS_ID_RESOLVER_TIMEOUT         | 3 seconds |
| recoveryDidKey          | `str`  | PDS_RECOVERY_DID_KEY            | null      |
| serviceHandleDomains    | `list` | PDS_SERVICE_HANDLE_DOMAINS      | |
| handleBackupNameservers | `list` | PDS_HANDLE_BACKUP_NAMESERVERS   | |
| enableDidDocWithSession | `bool` | PDS_ENABLE_DID_DOC_WITH_SESSION | `false` |

### Entryway

| name                                 | type   | env                                             |
| ---                                  | ---    | ---                                             |
| entrywayUrl                          | `str`  | PDS_ENTRYWAY_URL                                |
| entrywayDid                          | `str`  | PDS_ENTRYWAY_DID                                |
| entrywayJwtVerifyKeyK256PublicKeyHex | `str`  | PDS_ENTRYWAY_JWT_VERIFY_KEY_K256_PUBLIC_KEY_HEX |
| entrywayPlcRotationKey               | `str`  | PDS_ENTRYWAY_PLC_ROTATION_KEY                   |

### Invites

| name           | type   | env                 |
| ---            | ---    | ---                 |
| inviteRequired | `bool` | PDS_INVITE_REQUIRED |
| inviteInterval | `int`  | PDS_INVITE_INTERVAL |
| inviteEpoch    | `int`  | PDS_INVITE_EPOCH    |

### Email

| name                   | type   | env                           |
| ---                    | ---    | ---                           |
| emailSmtpUrl           | `str`  | PDS_EMAIL_SMTP_URL            |
| emailFromAddress       | `str`  | PDS_EMAIL_FROM_ADDRESS        |
| moderationEmailSmtpUrl | `str`  | PDS_MODERATION_EMAIL_SMTP_URL |
| moderationEmailAddress | `str`  | PDS_MODERATION_EMAIL_ADDRESS  |

### Subscription

| name                  | type  | env                         | default |
| ---                   | ---   | ---                         | ---     |
| maxSubscriptionBuffer | `int` | PDS_MAX_SUBSCRIPTION_BUFFER | `500`   |
| repoBackfillLimitMs   | `int` | PDS_REPO_BACKFILL_LIMIT_MS  | 1 day   |

### Appview

| name                     | type   | env                               |
| ---                      | ---    | ---                               |
| bskyAppViewUrl           | `str`  | PDS_BSKY_APP_VIEW_URL             |
| bskyAppViewDid           | `str`  | PDS_BSKY_APP_VIEW_DID             |
| bskyAppViewCdnUrlPattern | `str`  | PDS_BSKY_APP_VIEW_CDN_URL_PATTERN |

### Mod Service

| name          | type  | env |
| ---           | ---   | --- |
| modServiceUrl | `str` | PDS_MOD_SERVICE_URL |
| modServiceDid | `str` | PDS_MOD_SERVICE_DID |

### Report Service

| name             | type  | env |
| ---              | ---   | --- |
| reportServiceUrl | `str` | PDS_REPORT_SERVICE_URL |
| reportServiceDid | `str` | PDS_REPORT_SERVICE_DID |

### Rate Limits

| name               | type   | env                       |
| ---                | ---    | ---                       |
| rateLimitsEnabled  | `bool` | PDS_RATE_LIMITS_ENABLED   |
| rateLimitBypassKey | `str`  | PDS_RATE_LIMIT_BYPASS_KEY |
| rateLimitBypassIps | `list` | PDS_RATE_LIMIT_BYPASS_IPS |

### Redis

| name                 | type  | env |
| ---                  | ---   | --- |
| redisScratchAddress  | `str` | PDS_REDIS_SCRATCH_ADDRESS  |
| redisScratchPassword | `str` | PDS_REDIS_SCRATCH_PASSWORD |

### Crawlers

| name     | type   | env          | default                |
| ---      | ---    | ---          | ---                    |
| crawlers | `list` | PDS_CRAWLERS | `https://bsky.network` |

### Secrets

| name          | type   | env                | generate                |
| ---           | ---    | ---                | ---                     |
| dpopSecret    | `str`  | PDS_DPOP_SECRET    |                         |
| jwtSecret     | `str`  | PDS_JWT_SECRET     | `openssl rand --hex 16` |
| adminPassword | `str`  | PDS_ADMIN_PASSWORD |                         |

### Encryption

| name                            | type   | env                                       | generate |
| ---                             | ---    | ---                                       | ---      |
| plcRotationKeyKmsKeyId          | `str`  | PDS_PLC_ROTATION_KEY_KMS_KEY_ID           | |
| plcRotationKeyK256PrivateKeyHex | `str`  | PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX | See [plc rotation key generation](#plc-rotation-key) |

### Fetch

| name                  | type   | env                         | default               |
| ---                   | ---    | ---                         | ---                   |
| fetchMaxResponseSize  | `int`  | PDS_FETCH_MAX_RESPONSE_SIZE | `512 * 1024` // 512kb |
| disableSsrfProtection | `bool` | PDS_DISABLE_SSRF_PROTECTION | `false`               |

### Proxy

| name                  | type   | env                         | default            |
| ---                   | ---    | ---                         | ---                |
| proxyAllowHTTP2       | `bool` | PDS_PROXY_ALLOW_HTTP2       | `false`            |
| proxyHeadersTimeout   | `int`  | PDS_PROXY_HEADERS_TIMEOUT   | `10e3`             |
| proxyBodyTimeout      | `int`  | PDS_PROXY_BODY_TIMEOUT      | `20e3`             |
| proxyMaxResponseSize  | `int`  | PDS_PROXY_MAX_RESPONSE_SIZE | `10 * 1024 * 1024` |
| proxyMaxRetries       | `int`  | PDS_PROXY_MAX_RETRIES       | `0`                |
| proxyPreferCompressed | `bool` | PDS_PROXY_PREFER_COMPRESSED | `false`            |


### Misc

#### PLC Rotation Key
Generate a PLC rotation key.

```sh
openssl ecparam --name secp256k1 --genkey --noout --outform DER \
  | tail --bytes=+8 \
  | head --bytes=32 \
  | xxd --plain --cols 32
```
