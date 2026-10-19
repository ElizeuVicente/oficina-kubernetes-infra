output "region" {
  value = var.region
}

output "cluster_name" {
  value = aws_eks_cluster.oficina.name
}

output "vpc_id" {
  value = aws_vpc.oficina.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.oficina.vpc_config[0].cluster_security_group_id
}

output "backend_listener_arn" {
  value = aws_lb_listener.api.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}
