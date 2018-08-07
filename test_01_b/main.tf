provider "aws" {
  region = "eu-central-1"
}

variable certificate_arn {
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