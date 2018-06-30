//terraform {
//  backend "s3" {
//    bucket = "terraform-backend-home-site-alexeykuptsov-com"
//    key    = "terraform.tfstate"
//    region = "eu-central-1"
//  }
//}
//
provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.default.default_route_table_id}"
}

resource "aws_route" "to_internet" {
  route_table_id = "${aws_default_route_table.default.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.default.id}"
  availability_zone = "eu-central-1a"

  tags {
    Name = "${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_subnet" "empty" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.default.id}"
  availability_zone = "eu-central-1b"

  tags {
    Name = "${terraform.workspace}--empty"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_security_group" "allow_inbound_ssh" {
  name        = "${terraform.workspace}--allow-ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "${terraform.workspace}--load-balancer"
  description = "The load balancer security group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "default" {
  depends_on = ["aws_internet_gateway.default"]
  subnets = ["${aws_subnet.default.id}", "${aws_subnet.empty.id}"]
  name = "${terraform.workspace}"
  security_groups = ["${aws_security_group.load_balancer.id}"]

  tags {
    Environment = "${terraform.workspace}"
  }
}

variable "youtrack_version" {
  default = "2017.4.39406"
}


resource "aws_security_group" "nginx" {
  name        = "${terraform.workspace}--nginx"
  description = "nginx security group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.load_balancer.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami = "ami-337be65c"
  instance_type = "t2.nano"
  key_name = "eu-central-1-default"
  vpc_security_group_ids = ["${aws_security_group.allow_inbound_ssh.id}", "${aws_security_group.nginx.id}"]
  subnet_id = "${aws_subnet.default.id}"
  private_ip = "10.0.0.10"
  associate_public_ip_address = true

  tags {
    Name = "${terraform.workspace}--nginx"
    Environment = "${terraform.workspace}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y epel-release",
      "sudo yum install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]

    connection {
      type = "ssh"
      user = "centos"
      agent = true
    }
  }
}

resource "aws_lb_target_group" "nginx" {
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.default.id}"

  name = "${terraform.workspace}--nginx"
  tags {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_lb_target_group_attachment" "nginx" {
  port = 80
  target_group_arn = "${aws_lb_target_group.nginx.arn}"
  target_id = "${aws_instance.nginx.id}"
}

variable "root_hosted_zone_id" {
  default = "Z215JYRZR1TBD5"
}

variable "root_host_name" {
  default = "ak-test.me.uk"
}
