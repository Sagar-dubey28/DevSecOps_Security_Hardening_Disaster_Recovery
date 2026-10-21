# Incident response and troubleshooting runbook

## Severity and roles

- **SEV-1:** suspected account compromise, destructive data event, broad service outage. Page security and service owner immediately.
- **SEV-2:** security finding with contained scope or partial outage. Assign incident commander and recovery owner.
- **SEV-3:** isolated non-production finding or recoverable deployment failure.

Roles: incident commander, cloud/security responder, application owner, communications/record keeper. Record timestamps, decisions, commands, evidence locations, and approvals.

## First 15 minutes

1. Confirm scope and impact; open an incident record.
2. Avoid destroying evidence. Preserve CloudTrail events, GuardDuty finding JSON, CloudWatch logs, relevant EC2 metadata, and S3 object version IDs.
3. If compromise is plausible, restrict network access using approved controls, disable affected credentials/roles, and isolate the instance. Do not terminate it before evidence/snapshot capture unless immediate containment requires it.
4. Use a known-clean admin session. Never paste credentials or secret values into chat, ticket comments, or pipeline logs.
5. Notify the incident commander and security owner; determine regulatory/customer notification obligations.

## Deployment failure

1. Stop promotion and keep the last known-good version available.
2. Inspect GitLab job logs, artifact digest, Terraform plan, CloudWatch metrics/logs, EC2 status checks, and application health endpoint.
3. Roll back application artifact/configuration using the approved deployment mechanism. Do not run `terraform destroy` as a rollback strategy.
4. If infrastructure changed, compare the reviewed plan and current state; use a new reviewed corrective plan. Avoid manual console drift.
5. Validate service health, access controls, alarms, and logs; document the reason and evidence.

## Suspected AWS credential or OIDC abuse

1. Inspect CloudTrail `AssumeRoleWithWebIdentity`, role sessions, source IP, user agent, and changes after the session.
2. Verify GitLab project/ref claims and protected-branch settings.
3. Temporarily remove or narrow the role trust if necessary, coordinate active pipeline shutdown, and review permission policy.
4. Rotate/revoke any separate credentials that may have been exposed. OIDC reduces long-lived keys but does not eliminate risk from a compromised trusted pipeline.
5. Review all IAM, security group, S3 policy, CloudTrail, GuardDuty and logging changes for tampering.

## Backup / restore incident

1. Do not overwrite the only known-good backup.
2. Confirm bucket versioning and select the exact object version. Check checksum and retention.
3. Restore to a fresh isolated target. Scan/validate the contents before use.
4. For databases, use native consistent snapshots or database recovery procedures; do not restore raw live database files from a tar archive.
5. Obtain owner approval before cutover and record actual RTO/RPO.

## Troubleshooting commands

```bash
# Caller identity and role session
aws sts get-caller-identity

# CloudTrail recent lookup (adjust region/event name)
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity --max-results 20

# GuardDuty detector and findings
aws guardduty list-detectors
aws guardduty list-findings --detector-id DETECTOR_ID --max-results 20

# Instance managed status via SSM
aws ssm describe-instance-information

# S3 versioning and object versions
aws s3api get-bucket-versioning --bucket YOUR_BUCKET
aws s3api list-object-versions --bucket YOUR_BUCKET --prefix YOUR_PREFIX

# Linux service checks (run through SSM/authorized session)
sudo systemctl status amazon-ssm-agent auditd ufw
sudo journalctl -u amazon-ssm-agent --since '1 hour ago'
sudo ausearch -k identity --start recent
sudo ufw status verbose
sudo sshd -t
```

## Closure criteria

- Containment and recovery approved by the service/security owner.
- Required logs/evidence preserved and access to evidence restricted.
- Root cause, blast radius, recovery timeline, and control gaps documented.
- Follow-up owners and due dates assigned; recovery test repeated after remediation.
