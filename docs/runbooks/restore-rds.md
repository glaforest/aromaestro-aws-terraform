# Restauration RDS

## Depuis un snapshot automatique

### Via Console

1. RDS > Snapshots > Automated
2. Selectionner le snapshot desire
3. Actions > Restore snapshot
4. Configuration :
   - DB instance identifier : `aromaestro-{env}-mysql-restored`
   - Instance class : identique a l'original
   - VPC : identique
   - Subnet group : `aromaestro-{env}-db-subnet-group`
   - Security group : `aromaestro-{env}-sg-rds`
5. Restore DB instance
6. Attendre ~15 minutes
7. Mettre a jour l'endpoint dans les applications

### Via CLI

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier aromaestro-dev-mysql-restored \
  --db-snapshot-identifier <snapshot-id> \
  --db-instance-class db.t4g.micro \
  --db-subnet-group-name aromaestro-development-db-subnet-group \
  --vpc-security-group-ids <sg-rds-id>
```

## Validation post-restauration

1. Verifier la connectivite depuis une instance EC2
2. Verifier l'integrite des donnees
3. Tester les applications
