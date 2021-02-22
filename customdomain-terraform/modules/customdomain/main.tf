variable "zone_id" {
  type = "string"
}

variable "govuk_domain" {
  type = "string"
}

variable "govsvcuk_domain" {
  type = "string"
}

variable "aws_account_role_arn" {
  type = "string"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  assume_role {
    role_arn = var.aws_account_role_arn
  }
}
