/* This resource create a alb with an s3 bucket to log the access to it.
Currently this is set to be internal but can also be used to expose to the internet. */
   resource "aws_lb" "alb" {
  name            = "${ replace( var.name_prefix, "_", "-" ) }"
  internal        = false
  security_groups = ["${ aws_security_group.alb.id }"]
  subnets         = ["${ var.alb_subnets }"]

  access_logs {
    enabled = true
    bucket  = "${ aws_s3_bucket.vault_resources.id }"
    prefix  = "logs/alb_access_logs"
  }

  tags = "${ merge(
    map("Name", "${ var.name_prefix }"),
    var.tags ) }"
}



/* This will redirect request http to https */
resource "aws_lb_listener" "http" {
  load_balancer_arn = "${ aws_lb.alb.arn }"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${ aws_lb.alb.arn }"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-2018-06"
  certificate_arn   = "${aws_acm_certificate_validation.vault.certificate_arn}"

  default_action {
    target_group_arn = "${ aws_lb_target_group.tg.arn }"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${ replace( var.name_prefix, "_", "-" ) }"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${ var.vpc_id }"

  deregistration_delay = "1"

/* We hit the vault endpoint to make sure that the instance is healthy
before having it serving traffic. */
  health_check {
    path                = "/v1/sys/health"
    port                = "80"
    protocol            = "HTTP"
    interval            = "5"
    timeout             = "3"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    matcher             = "200"
  }

  tags = "${ merge(
    map("Name","${ var.name_prefix }"),
    var.tags ) }"
}
