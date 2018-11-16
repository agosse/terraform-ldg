resource "aws_lb" "alb" {
  name      = "alb"
  internal  = false
  load_balancer_type = "application"
  security_groups = ["${aws_default_security_group.default.id}","${aws_security_group.http_ingress.id}"]
  subnets         = ["${aws_subnet.subnet.*.id}"]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.alb.arn}"
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
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "${var.be_cert_arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg.arn}"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
}

