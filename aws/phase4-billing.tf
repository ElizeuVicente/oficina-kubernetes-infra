# Roteia apenas o webhook ao Billing; a rota da OS permanece no destino original.
resource "aws_lb_target_group" "phase4_billing" {
  count       = var.phase4_http_api_id == "" ? 0 : 1
  name        = "oficina-fase4-billing"
  port        = 30082
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.oficina.id
  health_check {
    path                = "/actuator/health"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_autoscaling_attachment" "phase4_billing" {
  count                  = var.phase4_http_api_id == "" ? 0 : 1
  autoscaling_group_name = aws_eks_node_group.oficina.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.phase4_billing[0].arn
}
resource "aws_lb_listener_rule" "phase4_billing" {
  count        = var.phase4_http_api_id == "" ? 0 : 1
  listener_arn = aws_lb_listener.api.arn
  priority     = 5
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.phase4_billing[0].arn
  }
  condition {
    path_pattern { values = ["/webhooks/mercadopago"] }
  }
}

# Recursos previamente existentes no HTTP API: importar antes de aplicar.
resource "aws_apigatewayv2_integration" "phase4_billing_webhook" {
  count                  = var.phase4_http_api_id == "" ? 0 : 1
  api_id                 = var.phase4_http_api_id
  integration_type       = "HTTP_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lb_listener.api.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.phase4[0].id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "phase4_billing_webhook" {
  count     = var.phase4_http_api_id == "" ? 0 : 1
  api_id    = var.phase4_http_api_id
  route_key = "POST /webhooks/mercadopago"
  target    = "integrations/${aws_apigatewayv2_integration.phase4_billing_webhook[0].id}"
}
