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

variable "r53_zone_id" {
  type        = "string"
  description = "The ID of the hosted zone to contain this record."
}

variable "r53_zone_name" {
  type        = "string"
  description = "The name of the record."
}

resource "aws_vpc_endpoint" "psn_service" {
  vpc_id            = "${var.vpc_id}"
  service_name      = "${var.vpc_endpoint}"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${var.security_group_ids}"]

  subnet_ids          = ["${var.subnet_ids}"]
  private_dns_enabled = false
}

resource "aws_route53_record" "psn_service" {
  zone_id = "${var.r53_zone_id}"
  name    = "psn.${var.r53_zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.psn_service.dns_entry[0], "dns_name")}"]
}
