variable "vpc_id" {
  type        = "string"
  description = "The ID of the VPC in which the endpoint will be used."
}

variable "vpc_endpoint" {
  type        = "string"
  description = "The service name, in the form com.amazonaws.region.service for AWS services."
}

variable "subnet_ids" {
  type        = "list"
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
}

variable "security_group_ids" {
  type        = "list"
  description = "The ID of one or more security groups to associate with the network interface."
}

resource "aws_vpc_endpoint" "psn_service" {
  vpc_id            = "${var.vpc_id}"
  service_name      = "${var.vpc_endpoint}"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${var.security_group_ids}"]

  subnet_ids          = ["${var.subnet_ids}"]
  private_dns_enabled = false
}

resource "aws_route53_zone" "private" {
  name = "vpc.internal"

  vpc {
    vpc_id = "${var.vpc_id}"
  }
}

resource "aws_route53_record" "psn_service" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "psn.${aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.psn_service.dns_entry[0], "dns_name")}"]
}

resource "aws_route53_record" "psn_regioned_service" {
  count   = 2
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "psn.${count.index+1}.${aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.psn_service.dns_entry[count.index+1], "dns_name")}"]
}
