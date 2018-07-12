###
### LOCALS
###

locals {
  name = "cats-or-dogs"
}

###
### DATA SOURCES
###

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "template_file" "bucket_policy" {
  template = "${file("bucket_policy.json")}"

  vars {
    bucket_arn = "${aws_s3_bucket.this.arn}"
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "${local.name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = "${aws_s3_bucket.this.id}"
  policy = "${data.template_file.bucket_policy.rendered}"
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = "${aws_s3_bucket.this.id}"
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = "${aws_s3_bucket.this.arn}"
}
