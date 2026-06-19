terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket         = "cineflow-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CineFlow"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ============================================================================
# VPC & Networking
# ============================================================================

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "cineflow-${var.environment}"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Kubernetes networking
  enable_network_address_usage_metrics = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================================
# EKS Cluster
# ============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name    = "cineflow-${var.environment}"
  cluster_version = var.kubernetes_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  # Cluster security group
  cluster_security_group_additional_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Node groups
  eks_managed_node_groups = {
    general = {
      name = "general-nodes"

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      disk_size = 100

      tags = {
        NodeGroup = "general"
      }

      labels = {
        Environment = var.environment
        NodeType    = "general"
      }

      taints = []
    }

    gpu = {
      name = "gpu-nodes"

      instance_types = var.gpu_instance_types
      capacity_type  = "SPOT"

      min_size     = var.gpu_min_size
      max_size     = var.gpu_max_size
      desired_size = var.gpu_desired_size

      disk_size = 150

      tags = {
        NodeGroup = "gpu"
      }

      labels = {
        Environment = var.environment
        NodeType    = "gpu"
        GPUEnabled  = "true"
      }

      taints = [
        {
          key    = "gpu"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    ebs-csi-driver = {
      most_recent = true
    }
  }
}

# ============================================================================
# RDS PostgreSQL
# ============================================================================

module "rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 6.1"

  identifier = "cineflow-${var.environment}"

  engine               = "postgres"
  engine_version       = var.postgres_version
  family               = "postgres${var.postgres_version}"
  major_engine_version = split(".", var.postgres_version)[0]
  instance_class       = var.rds_instance_class
  storage_encrypted    = true
  allocated_storage    = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  db_name  = var.database_name
  username = var.database_username
  password = random_password.db_password.result
  port     = 5432

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = "cineflow-${var.environment}-final-snapshot"

  backup_retention_period = var.environment == "production" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  multi_az = var.environment == "production"

  performance_insights_enabled = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Database = "Primary"
  }
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_security_group" "rds" {
  name_prefix = "cineflow-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================================
# ElastiCache Redis
# ============================================================================

module "redis" {
  source = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.1"

  cluster_id           = "cineflow-${var.environment}"
  engine               = "redis"
  node_type           = var.redis_node_type
  num_cache_nodes     = var.redis_num_nodes
  parameter_group_name = "default.redis7"
  engine_version      = var.redis_version
  port                = 6379

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = var.environment == "production"
  multi_az_enabled          = var.environment == "production"

  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"

  tags = {
    Cache = "Redis"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "cineflow-${var.environment}-redis"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "redis" {
  name_prefix = "cineflow-redis-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================================
# S3 Buckets
# ============================================================================

module "s3_assets" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.11"

  bucket = "cineflow-assets-${var.environment}"

  acl            = "private"
  attach_policy  = true
  policy         = data.aws_iam_policy_document.s3_assets.json

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_assets" {
  statement {
    sid    = "EnforceSSLOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [module.s3_assets.s3_bucket_arn, "${module.s3_assets.s3_bucket_arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ============================================================================
# Secrets Manager
# ============================================================================

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "cineflow-db-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.database_username
    password = random_password.db_password.result
    host     = module.rds.db_instance_address
    port     = 5432
    dbname   = var.database_name
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name_prefix             = "cineflow-api-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    jwt_secret = random_password.jwt_secret.result
    api_key    = random_password.api_key.result
  })
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

resource "random_password" "api_key" {
  length  = 32
  special = true
}

# ============================================================================
# CloudWatch Logging
# ============================================================================

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/cineflow-${var.environment}"
  retention_in_days = var.log_retention_days
}

# ============================================================================
# Kubernetes Provider Configuration
# ============================================================================

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# ============================================================================
# Outputs
# ============================================================================

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "redis_endpoint" {
  value = module.redis.primary_configuration_endpoint_address
}

output "s3_assets_bucket" {
  value = module.s3_assets.s3_bucket_id
}
