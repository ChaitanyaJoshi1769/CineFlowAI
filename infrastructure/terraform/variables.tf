variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "Instance types for general node group"
  type        = list(string)
  default     = ["t3.2xlarge", "t3a.2xlarge"]
}

variable "node_group_min_size" {
  description = "Minimum size of general node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum size of general node group"
  type        = number
  default     = 10
}

variable "node_group_desired_size" {
  description = "Desired size of general node group"
  type        = number
  default     = 5
}

variable "gpu_instance_types" {
  description = "Instance types for GPU node group"
  type        = list(string)
  default     = ["g4dn.2xlarge", "g4dn.4xlarge"]
}

variable "gpu_min_size" {
  description = "Minimum size of GPU node group"
  type        = number
  default     = 0
}

variable "gpu_max_size" {
  description = "Maximum size of GPU node group"
  type        = number
  default     = 20
}

variable "gpu_desired_size" {
  description = "Desired size of GPU node group"
  type        = number
  default     = 2
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6i.2xlarge"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 500
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
  default     = 2000
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "cineflow"
}

variable "database_username" {
  description = "Database username"
  type        = string
  sensitive   = true
  default     = "cineflow_admin"
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.r6g.xlarge"
}

variable "redis_num_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 3
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "CineFlow"
    ManagedBy   = "Terraform"
    CreatedAt   = "2024"
  }
}
