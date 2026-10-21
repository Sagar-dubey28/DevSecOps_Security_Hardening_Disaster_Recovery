#!/usr/bin/env bash
set -Eeuo pipefail

: "${RESTORE_URI:?Set RESTORE_URI to the exact s3://bucket/key.tar.gz backup object}"
: "${RESTORE_DIR:?Set RESTORE_DIR to an isolated restore destination}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ALLOW_OVERWRITE="${ALLOW_OVERWRITE:-false}"
command -v aws >/dev/null || { echo "AWS CLI v2 is required" >&2; exit 2; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 2; }
[[ "$RESTORE_URI" == s3://* ]] || { echo "RESTORE_URI must begin with s3://" >&2; exit 2; }

if [[ -e "$RESTORE_DIR" ]]; then
  if [[ -n "$(find "$RESTORE_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" && "$ALLOW_OVERWRITE" != "true" ]]; then
    echo "Refusing to restore into non-empty directory. Choose an empty isolated directory or explicitly set ALLOW_OVERWRITE=true after approval." >&2
    exit 3
  fi
else
  mkdir -p "$RESTORE_DIR"
fi

umask 077
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
archive="${workdir}/restore.tar.gz"
checksum="${archive}.sha256"
aws s3 cp "$RESTORE_URI" "$archive" --region "$AWS_DEFAULT_REGION" --only-show-errors
aws s3 cp "${RESTORE_URI}.sha256" "$checksum" --region "$AWS_DEFAULT_REGION" --only-show-errors
expected="$(awk '{print $1}' "$checksum")"
actual="$(sha256sum "$archive" | awk '{print $1}')"
[[ "$expected" == "$actual" ]] || { echo "Checksum mismatch; restore aborted" >&2; exit 4; }
# Reject absolute paths and parent traversal before extracting untrusted archive content.
if tar -tzf "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  echo "Unsafe archive path detected; restore aborted" >&2
  exit 5
fi
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$RESTORE_DIR"
printf 'Restore extracted to %s. Validate application health and data consistency before cutover.\n' "$RESTORE_DIR"
