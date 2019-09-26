terraform {
  required_version = ">= 0.12"
}

###
### VARIABLES
###

variable "url_suffix" {
  default     = "amazonaws.com"
  description = "URL suffix associated with the current partition"
  type        = string
}

###
### LOCALS
###

locals {
  policy_name = "INSTANCE_CATS_OR_DOGS"
}

###
### DATA SOURCES
###

data "aws_partition" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "template_file" "instance_policy" {
  template = file("iam_policy.json")

  vars = {
    partition  = data.aws_partition.current.partition
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
  }
}

data "aws_iam_policy_document" "instance_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${var.url_suffix}"]
    }
  }
}

###
### RESOURCES
###

resource "aws_iam_role" "instance" {
  name               = local.policy_name
  assume_role_policy = data.aws_iam_policy_document.instance_trust_policy.json
}

resource "aws_iam_role_policy" "instance" {
  name_prefix = "${local.policy_name}_"
  policy      = data.template_file.instance_policy.rendered
  role        = aws_iam_role.instance.id
}

resource "aws_iam_instance_profile" "instance" {
  name = local.policy_name
  role = aws_iam_role.instance.name
}

###
### OUTPUTS
###

output "instance_role_arn" {
  description = "ARN of the IAM Role for the Cats or Dogs instance role"
  value       = aws_iam_role.instance.arn
}

output "instance_role_name" {
  description = "Name of the IAM Role for the Cats or Dogs instance role"
  value       = aws_iam_role.instance.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM Instance Profile for the Cats or Dogs instance role"
  value       = aws_iam_role.instance.arn
}

output "instance_profile_name" {
  description = "Name of the IAM Instance Profile for the Cats or Dogs instance role"
  value       = aws_iam_role.instance.name
}
