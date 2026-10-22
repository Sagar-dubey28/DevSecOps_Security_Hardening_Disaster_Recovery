# Recovery Time Objective (RTO) and Recovery Point Objective (RPO)

These are **initial targets for the sample non-critical application**. The service owner must approve targets based on business impact and measured restore tests.

| Tier | RTO target | RPO target | Backup / recovery approach |
|---|---:|---:|---|
| Sandbox / demo | 8 hours | 24 hours | Daily archive, S3 versioning, manual isolated restore |
| Production candidate (not yet implemented by this starter) | 4 hours | 1 hour | Scheduled application-consistent backup, cross-region copy, automated infrastructure recreation |

## Definitions

- **RTO:** maximum target elapsed time from declared outage to restored service.
- **RPO:** maximum tolerable data loss measured in time before the outage.
- S3 versioning preserves object versions, but does not schedule backups, guarantee database consistency, or provide cross-region recovery by itself.
- A tar archive of a live database directory is not a valid database backup. Use database-native snapshots/dumps, quiesce writes, or application-consistent backup hooks.

## Backup controls

1. Enable versioning, encryption, public-access block, TLS-only bucket policy, and lifecycle retention on the backup bucket.
2. Limit backup writer to a dedicated prefix and restore readers to approved operators.
3. For ransomware resilience, use cross-account replication and/or S3 Object Lock with governance/compliance mode approved by security/legal stakeholders.
4. Store checksum alongside each archive and periodically verify it. Preserve audit logs separately from application backups.
5. Record backup timestamp, source, object version ID, checksum, operator, and test result.

## Recovery procedure

1. Declare incident and record start time; assign incident commander and recovery operator.
2. Isolate affected resources if compromise is suspected. Preserve CloudTrail, GuardDuty, OS/audit logs and snapshots before remediation.
3. Select a known-good backup version and immutable/versioned deployment artifact.
4. Recreate infrastructure from reviewed Terraform state/code in an isolated recovery environment.
5. Restore into a new directory/volume or database instance. Verify checksum, schema/data integrity, permissions, and application health.
6. Validate security posture, secrets, access paths, and monitoring before traffic cutover.
7. Obtain service-owner approval, perform controlled cutover, monitor, and document actual RTO/RPO.
8. Preserve evidence and update runbooks and controls from lessons learned.



For each test, capture `incident_declared_at`, `service_restored_at`, last recoverable data timestamp, selected backup object version, and validation results. Actual RTO is elapsed restoration time. Actual RPO is outage time minus timestamp of the latest valid recovered data. Do not claim the targets are met until a timed recovery test demonstrates it.
