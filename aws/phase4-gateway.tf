# Adiciona apenas a rota da OS ao HTTP API existente; o webhook anterior permanece intacto.
variable "phase4_http_api_id" {
  description = "ID do HTTP API existente; vazio desabilita a rota da Fase 4."
  type        = string
  default     = ""
}

resource "aws_security_group" "phase4_vpc_link" {
  count       = var.phase4_http_api_id == "" ? 0 : 1
  name_prefix = "oficina-fase4-vpc-link-"
  vpc_id      = aws_vpc.oficina.id
  description = "Acesso do API Gateway ao ALB interno"
}

resource "aws_vpc_security_group_egress_rule" "phase4_to_alb" {
  count             = var.phase4_http_api_id == "" ? 0 : 1
  security_group_id = aws_security_group.phase4_vpc_link[0].id
  cidr_ipv4         = aws_vpc.oficina.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_apigatewayv2_vpc_link" "phase4" {
  count              = var.phase4_http_api_id == "" ? 0 : 1
  name               = "oficina-fase4-private"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.phase4_vpc_link[0].id]
}

resource "aws_apigatewayv2_integration" "phase4_os" {
  count                  = var.phase4_http_api_id == "" ? 0 : 1
  api_id                 = var.phase4_http_api_id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.api.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.phase4[0].id
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "phase4_os" {
  count     = var.phase4_http_api_id == "" ? 0 : 1
  api_id    = var.phase4_http_api_id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.phase4_os[0].id}"
}
