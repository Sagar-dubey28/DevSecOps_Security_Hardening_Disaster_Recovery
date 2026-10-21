# Test evidence, failure simulation, and rollback

> Perform tests only in a dedicated sandbox/account with explicit authorization. Never simulate destructive events against production or real customer data.

## Evidence record template

For each test, store: test ID, date/time UTC, operator, account/region, commit SHA, expected result, actual result, log/artifact links, screenshots if required, findings, remediation ticket, approver, and cleanup confirmation. Redact secrets and personal data.

| ID | Test | Safe method | Expected result | Evidence |
|---|---|---|---|---|
| SEC-01 | Terraform misconfiguration | Add a temporary insecure fixture in a test branch (not deployed) | Checkov fails pipeline | Job log and SARIF/report |
| SEC-02 | Critical dependency/container CVE | Use a deliberately vulnerable sample image/dependency in isolated test | Trivy exits non-zero for HIGH/CRITICAL | Trivy output and fixed commit |
| SEC-03 | Secret handling | Add a fake canary secret only to a disposable test branch | Secret scanner flags it; remove and rotate test value | Scanner report; no real secret in evidence |
| SEC-04 | Unauthorized deploy | Attempt apply from unprotected branch or user without approval | IAM trust or GitLab protected environment denies action | Pipeline and CloudTrail event |
| OPS-01 | SSH exposure | Inspect security group rules | No inbound TCP/22 from public internet | Terraform plan and SG rules |
| OPS-02 | Instance access | Connect using approved SSM identity | SSM works without public IP/SSH | Session Manager session record |
| OPS-03 | Backup/restore | Back up harmless fixture data and restore to isolated temp directory | Checksum matches; restored file hash matches | S3 version ID and checksums |
| OPS-04 | Backup tamper detection | Alter a local test checksum or archive copy | Restore script rejects mismatch | Script output |
| OPS-05 | Deployment rollback | Deploy known-bad app artifact in sandbox | Health check fails and operator rolls back to last known-good digest | Pipeline, health logs, timestamps |
| OPS-06 | Security notification | In authorized sandbox, use GuardDuty sample findings feature | EventBridge sends SNS notification | EventBridge/SNS delivery evidence |
| DR-01 | Recovery timing | Restore known-good backup and recreate test infrastructure | Actual RTO/RPO measured against approved targets | Timeline and owner sign-off |

## Rollback principles

- Application rollback should select an immutable previously approved image/artifact digest, not rebuild an old branch and assume it is identical.
- Database rollback requires a separate data migration/recovery plan; schema changes may not be reversible.
- Terraform rollback means reviewing a new plan that restores the intended configuration. Do not use `terraform destroy` as a generic rollback.
- Keep state backup and a tested state-recovery procedure. Do not manually edit state unless directed by an experienced Terraform operator with a backup.
- Rollback requires the designated approver and incident/change record. Verify health and security controls afterward.

## Evidence storage

Store reports as GitLab job artifacts with retention appropriate to policy, and archive approved evidence in a restricted, versioned audit location. Never commit raw state, plan files containing secrets, credentials, private keys, or unredacted incident data.

## Completion checklist

- [ ] `terraform fmt -check -recursive` passes.
- [ ] `terraform validate` passes after provider/backend configuration.
- [ ] Checkov scans root and modules; findings triaged.
- [ ] Trivy and SonarQube gates configured and required where applicable.
- [ ] GitLab OIDC trust is restricted to exact project/ref and tested.
- [ ] Production environment approvals and protected branches configured.
- [ ] Ansible check mode reviewed; SSH/SSM access verified before hardening.
- [ ] CloudTrail, GuardDuty, CloudWatch, and SNS notifications tested.
- [ ] Backup version, checksum, retention, and restore validated.
- [ ] Timed DR exercise demonstrates measured RTO/RPO.
- [ ] Operational handover and exception process approved.
