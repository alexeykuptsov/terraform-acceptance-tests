variable certificate_arn {
  default = "arn:aws:acm:eu-central-1:251104947269:certificate/67574c29-c39b-4082-ae36-ba1384a2ecfe"
}

variable target_group_arn {
}

variable load_balancer_arn {
}

resource "aws_lb_listener" "aksite" {
  "default_action" {
    target_group_arn = "${var.target_group_arn}"
    type = "forward"
  }
  load_balancer_arn = "${var.load_balancer_arn}"
  port = 443
  protocol = "HTTPS"
  certificate_arn = "${var.certificate_arn}"
}