# Chiffrement

## Au repos

| Service | Methode | Cle |
|---|---|---|
| EBS | Chiffrement par defaut au compte | AWS managed KMS |
| S3 (assets) | SSE-KMS | AWS managed KMS |
| S3 (logs) | SSE-S3 (AES256) | AWS managed |
| RDS | KMS | AWS managed KMS |
| Terraform State | SSE-KMS | AWS managed KMS |

## En transit

| Service | Methode |
|---|---|
| S3 | Bucket policy deny non-TLS |
| RDS | require_secure_transport = ON |
| Tailscale | WireGuard (chiffrement bout-en-bout) |
| SSM Session Manager | TLS |
| AWS API calls | HTTPS (TLS 1.2+) |
