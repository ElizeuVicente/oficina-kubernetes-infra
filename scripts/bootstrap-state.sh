#!/usr/bin/env bash
set -euo pipefail

# Executar APENAS quando o aluno autorizar recursos AWS cobrados.
if [[ "${OFICINA_ALLOW_AWS_CREATE:-}" != "yes" ]]; then
  echo "Bloqueado: defina OFICINA_ALLOW_AWS_CREATE=yes somente na janela AWS autorizada." >&2
  exit 2
fi
bucket="${1:-}"
profile="${AWS_PROFILE:-fiap-lab}"
if [[ ! "$bucket" =~ ^[a-z0-9][a-z0-9.-]{2,61}[a-z0-9]$ ]]; then
  echo "Informe nome DNS válido de bucket como primeiro argumento." >&2
  exit 2
fi
aws sts get-caller-identity --profile "$profile" --query Arn --output text >/dev/null
aws s3api create-bucket --bucket "$bucket" --region us-east-1 --profile "$profile"
aws s3api put-public-access-block --bucket "$bucket" --profile "$profile" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket "$bucket" --profile "$profile" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-versioning --bucket "$bucket" --profile "$profile" \
  --versioning-configuration Status=Enabled
echo "Bucket de state criado; restrinja IAM e verifique criptografia, versionamento e acesso público antes de usar."
