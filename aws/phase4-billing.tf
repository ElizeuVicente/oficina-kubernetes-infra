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
