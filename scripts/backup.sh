#!/usr/bin/env bash
set -Eeuo pipefail

: "${BACKUP_BUCKET:?Set BACKUP_BUCKET to a private, versioned S3 bucket}"
: "${SOURCE_DIR:?Set SOURCE_DIR to the directory to back up}"
BACKUP_PREFIX="${BACKUP_PREFIX:-task5/backups}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
[[ -d "$SOURCE_DIR" ]] || { echo "Source directory not found: $SOURCE_DIR" >&2; exit 2; }
command -v aws >/dev/null || { echo "AWS CLI v2 is required" >&2; exit 2; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 2; }

umask 077
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="${workdir}/backup-${stamp}.tar.gz"
key="${BACKUP_PREFIX%/}/${stamp}.tar.gz"

# Archive the directory contents; use database-native consistent backups for DB data.
tar --acls --xattrs -czf "$archive" -C "$SOURCE_DIR" .
sha256sum "$archive" > "${archive}.sha256"
aws s3 cp "$archive" "s3://${BACKUP_BUCKET}/${key}" --region "$AWS_DEFAULT_REGION" --sse AES256 --only-show-errors
aws s3 cp "${archive}.sha256" "s3://${BACKUP_BUCKET}/${key}.sha256" --region "$AWS_DEFAULT_REGION" --sse AES256 --only-show-errors
version_id="$(aws s3api head-object --bucket "$BACKUP_BUCKET" --key "$key" --region "$AWS_DEFAULT_REGION" --query VersionId --output text)"
printf 'Backup uploaded: s3://%s/%s\nVersionId: %s\n' "$BACKUP_BUCKET" "$key" "$version_id"
echo "Verify bucket versioning, retention, encryption, and checksum before treating this as a recovery point."
