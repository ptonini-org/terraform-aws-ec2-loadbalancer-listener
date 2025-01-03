resource "aws_lb_listener" "this" {
  load_balancer_arn = var.load_balancer.arn
  port              = var.port
  protocol          = var.protocol
  certificate_arn   = var.certificate.arn

  dynamic "default_action" {
    for_each = var.default_actions
    content {
      order            = default_action.key
      type             = default_action.value.type
      target_group_arn = default_action.value.type == "forward" ? default_action.value.target_group_arn : null

      dynamic "redirect" {
        for_each = default_action.value.redirect[*]
        content {
          host        = redirect.value.host
          path        = redirect.value.path
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }
    }
  }
}

module "rules" {
  source           = "app.terraform.io/ptonini-org/ec2-loadbalancer-listener-rule/aws"
  version          = "~> 1.0.0"
  for_each         = var.rules
  listener_arn     = aws_lb_listener.this.arn
  priority         = each.key
  type             = each.value.type
  target_group_arn = each.value.target_group_arn
  redirects        = each.value.redirects
  conditions       = each.value.conditions
}