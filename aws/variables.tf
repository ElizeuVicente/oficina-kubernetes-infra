variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "oficina-fase3"
}

variable "availability_zones" {
  description = "Duas AZs permitidas para EKS na conta do laboratório."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2 && var.availability_zones[0] != var.availability_zones[1]
    error_message = "Informe duas AZs diferentes."
  }
}

variable "eks_cluster_role_arn" {
  description = "ARN do LabEksClusterRole pré-existente no Learner Lab."
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN do LabEksNodeRole pré-existente no Learner Lab."
  type        = string
}

variable "admin_cidrs" {
  description = "CIDRs públicos que podem acessar o endpoint Kubernetes. Nunca use 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Restrinja o endpoint Kubernetes a IPs de administração conhecidos."
  }
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 1

  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 2
    error_message = "O laboratório suporta apenas 1 ou 2 nós neste plano de custo."
  }
}
