resource "aws_iam_policy" "external_secrets_operator_policy" {
  name        = "external-secrets-operator-policy"
  description = "Policy for External Secrets Operator to access SecretsManager, ParameterStore, and KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAccessToSecretsManager"
        Effect   = "Allow"
        Action   = [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:${local.account_id}:secret:*"
        ]
      },
      {
        Sid      = "AllowAccessToParameterStore"
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:us-east-1:${local.account_id}:parameter/*"
        ]
      },
      {
        Sid      = "AllowAccessToKMSDefaultKey"
        Effect   = "Allow"
        Action   = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:us-east-1:${local.account_id}:key/${var.kms_key_id}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets_operator_role" {
  name = "external-secrets-operator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "TrustMyRole"
        Effect    = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets-operator-service-account"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_operator_policy_attachment" {
  role       = aws_iam_role.external_secrets_operator_role.name
  policy_arn = aws_iam_policy.external_secrets_operator_policy.arn
}

resource "kubernetes_service_account" "external_secrets_operator_service_account" {
  metadata {
    name      = "external-secrets-operator-service-account"
    namespace = "external-secrets"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets_operator_role.arn
    }
  }
  depends_on = [ module.eks ]
}

resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets-operator"
  namespace  = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  create_namespace = true
  version    = "0.14.0"
  
  values = [
    <<-EOT
      clusterName: "${module.eks.cluster_name}"
      clusterEndpoint: "${module.eks.cluster_endpoint}"
      serviceAccount:
        name: external-secrets-operator-service-account
        annotations:
          eks.amazonaws.com/role-arn: "${aws_iam_role.external_secrets_operator_role.arn}"
    EOT
  ]

  depends_on = [
    module.eks,
    aws_iam_role.external_secrets_operator_role
  ]
}
