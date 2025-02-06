resource "aws_iam_role" "rds_role" {
  name = "dev-cluster-orders-rds-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "rds_access_policy" {
  name        = "rds-access-policy"
  description = "Allow access to RDS for the IAM user"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${local.region}:${local.account_id}:dbuser/rds_iam_user"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_access_policy_attachment" {
  policy_arn = aws_iam_policy.rds_access_policy.arn
  role       = aws_iam_role.rds_role.name
}

resource "aws_db_instance" "rds" {
  identifier                       = "dev-cluster-rds"
  engine                           = "postgres"
  instance_class                   = "db.t3.micro"
  allocated_storage                = 20
  db_subnet_group_name             = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  multi_az                         = false
  storage_type                     = "gp2"
  iam_database_authentication_enabled = true
  db_name                          = "${var.db_name}"
  username                         = "${var.db_username}"
  password                         = "${var.db_password}"
  skip_final_snapshot              = true
  tags                             = local.tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "dev-cluster-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound traffic to RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.private_subnets
  }

  tags = local.tags
}

resource "kubernetes_service_account" "orders_service_account" {
  metadata {
    name      = "orders-service-account"
    namespace = kubernetes_namespace.orders.metadata[0].name
  }
}

resource "kubernetes_service_account" "inventory_service_account" {
  metadata {
    name      = "inventory-service-account"
    namespace = kubernetes_namespace.inventory.metadata[0].name
  }
}

resource "aws_iam_role" "orders_service_account_role" {
  name = "orders-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "orders_policy_attachment" {
  policy_arn = aws_iam_policy.rds_access_policy.arn
  role       = aws_iam_role.orders_service_account_role.name
}

resource "aws_iam_role" "inventory_service_account_role" {
  name = "inventory-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "inventory_policy_attachment" {
  policy_arn = aws_iam_policy.rds_access_policy.arn
  role       = aws_iam_role.inventory_service_account_role.name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}