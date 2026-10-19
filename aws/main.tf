locals {
  public_cidrs  = ["10.42.0.0/20", "10.42.16.0/20"]
  private_cidrs = ["10.42.32.0/20", "10.42.48.0/20"]
}

resource "aws_vpc" "oficina" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.cluster_name}-vpc" }
}

resource "aws_internet_gateway" "oficina" {
  vpc_id = aws_vpc.oficina.id
  tags   = { Name = "${var.cluster_name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.oficina.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.oficina.id
  cidr_block              = local.private_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.oficina.id
  tags   = { Name = "${var.cluster_name}-public" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.oficina.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.oficina.id
  tags   = { Name = "${var.cluster_name}-private-no-internet" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_eks_cluster" "oficina" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.admin_cidrs
  }

  tags = { Name = var.cluster_name }
}

resource "aws_eks_node_group" "oficina" {
  cluster_name    = aws_eks_cluster.oficina.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = [var.node_instance_type]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = { Name = "${var.cluster_name}-nodes" }
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.oficina.name
  addon_name   = "metrics-server"
  depends_on   = [aws_eks_node_group.oficina]
}

# Um ALB interno atende dois NodePorts, sem expor a API diretamente à internet.
resource "aws_security_group" "alb" {
  name_prefix = "oficina-fase3-alb-"
  vpc_id      = aws_vpc.oficina.id
  description = "ALB interno acessado pelo API Gateway VPC Link"
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_vpc.oficina.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Somente origem da VPC privada; API Gateway controla acesso externo"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_eks_cluster.oficina.vpc_config[0].cluster_security_group_id
  from_port                    = 30080
  to_port                      = 30081
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_eks_cluster.oficina.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 30080
  to_port                      = 30081
  ip_protocol                  = "tcp"
}

resource "aws_lb" "api" {
  name               = "oficina-fase3-internal"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "api" {
  for_each    = { prod = 30080, homolog = 30081 }
  name        = "oficina-fase3-${each.key}"
  port        = each.value
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.oficina.id

  health_check {
    path                = each.key == "prod" ? "/actuator/health/readiness" : "/homolog/actuator/health/readiness"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "api" {
  for_each               = aws_lb_target_group.api
  autoscaling_group_name = aws_eks_node_group.oficina.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = each.value.arn
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["prod"].arn
  }
}

resource "aws_lb_listener_rule" "homolog" {
  listener_arn = aws_lb_listener.api.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api["homolog"].arn
  }
  condition {
    path_pattern { values = ["/homolog/*"] }
  }
}

resource "aws_ecr_repository" "api" {
  name                 = "oficina-fase3-api"
  image_tag_mutability = "IMMUTABLE"
  # O laboratório é efêmero: permitir que terraform destroy remova imagens
  # deste repositório específico, evitando armazenamento residual.
  force_delete = true
  image_scanning_configuration { scan_on_push = true }
}
