###
### LOCALS
###

locals {
  name            = "cats-or-dogs"
  name_id         = "${local.name}-${random_string.this.id}"
  bucket          = "${local.name}-${data.aws_caller_identity.current.account_id}"
  ami_name_filter = "spel-minimal-centos-7-hvm-*.x86_64-gp2"
  ami_name_regex  = "spel-minimal-centos-7-hvm-\\d{4}\\.\\d{2}\\.\\d{1}\\.x86_64-gp2"
  instance_role   = "INSTANCE_CATS_OR_DOGS"
  vpc_id          = "${data.aws_subnet.lb.0.vpc_id}"
}

###
### DATA SOURCES
###

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "this" {
  most_recent = "true"

  name_regex = "${local.ami_name_regex}"

  filter {
    name   = "owner-id"
    values = ["${var.ami_owner}"]
  }

  filter {
    name   = "name"
    values = ["${local.ami_name_filter}"]
  }
}

data "aws_subnet" "lb" {
  count = "${length(var.lb_subnet_ids)}"

  id = "${var.lb_subnet_ids[count.index]}"
}

###
### RESOURCES
###

# Generate a random id for each deployment
resource "random_string" "this" {
  length  = 8
  special = "false"
}

# Manage bucket contents
locals {
  s3_sync_static = [
    "aws s3 sync --delete --acl public-read",
    "${path.module}/static",
    "s3://${local.bucket}/${random_string.this.id}/static",
  ]

  s3_sync_salt = [
    "aws s3 sync --delete",
    "${path.module}/salt",
    "s3://${local.bucket}/${random_string.this.id}/salt",
  ]

  s3_sync_appscript = [
    "aws s3 sync --exclude \"*\" --include appscript.sh",
    "${path.module}",
    "s3://${local.bucket}/${random_string.this.id}",
  ]

  s3_rm = [
    "aws s3 rm --recursive",
    "s3://${local.bucket}/${random_string.this.id}",
  ]
}

resource "null_resource" "sync_s3" {
  provisioner "local-exec" {
    command = "${join(" ", local.s3_sync_static)}"
  }

  provisioner "local-exec" {
    command = "${join(" ", local.s3_sync_salt)}"
  }

  provisioner "local-exec" {
    command = "${join(" ", local.s3_sync_appscript)}"
  }

  provisioner "local-exec" {
    command = "${join(" ", local.s3_rm)}"
    when    = "destroy"
  }

  triggers = {
    s3_sync_static    = "${join(" ", local.s3_sync_static)}"
    s3_sync_salt      = "${join(" ", local.s3_sync_salt)}"
    s3_sync_appscript = "${join(" ", local.s3_sync_appscript)}"
  }
}

# Manage load balancer
resource "aws_lb" "this" {
  name            = "${local.name_id}"
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${var.lb_subnet_ids}"]
  internal        = "${var.lb_internal}"
}

resource "aws_lb_target_group" "this" {
  name     = "${local.name_id}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${local.vpc_id}"
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.this.arn}"
    type             = "forward"
  }
}

# Manage security groups
resource "aws_security_group" "lb" {
  name        = "${local.name_id}-lb"
  description = "Rules required for operation of ${local.name_id}"
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${local.name_id}-ec2"
  description = "Rules required for operation of ${local.name_id}"
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lb_to_ec2_tcp_80" {
  security_group_id        = "${aws_security_group.lb.id}"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.ec2.id}"
}

# Manage autoscaling group
resource "random_shuffle" "cats_az" {
  input        = ["${data.aws_subnet.lb.*.availability_zone}"]
  result_count = 1
}

locals {
  appscript_url    = "s3://${local.bucket}/${random_string.this.id}/appscript.sh"
  appscript_params = "${local.bucket}/${random_string.this.id} ${random_shuffle.cats_az.result[0]}"
}

module "autoscaling_group" {
  source = "git::https://github.com/plus3it/terraform-aws-watchmaker//modules/lx-autoscale?ref=1.5.2"

  Name            = "${local.name_id}"
  OnFailureAction = ""
  DisableRollback = "true"

  AmiId                = "${data.aws_ami.this.id}"
  AmiDistro            = "CentOS"
  AppScriptUrl         = "${local.appscript_url}"
  AppScriptParams      = "${local.appscript_params}"
  CfnBootstrapUtilsUrl = "${var.cfn_bootstrap_utils_url}"
  CfnGetPipUrl         = "${var.cfn_get_pip_url}"
  CfnEndpointUrl       = "${var.cfn_endpoint_url}"
  CloudWatchAgentUrl   = "${var.cloudwatch_agent_url}"
  KeyPairName          = "${var.key_pair_name}"
  InstanceRole         = "${local.instance_role}"
  InstanceType         = "${var.instance_type}"
  NoReboot             = "true"
  PypiIndexUrl         = "${var.pypi_index_url}"
  SecurityGroupIds     = "${join(",", compact(concat(list(aws_security_group.ec2.id), var.ec2_extra_security_group_ids)))}"
  SubnetIds            = "${join(",", var.ec2_subnet_ids)}"
  TargetGroupArns      = "${aws_lb_target_group.this.arn}"
  ToggleNewInstances   = "${var.toggle_update}"

  WatchmakerEnvironment = "${var.environment}"
  WatchmakerConfig      = "${var.watchmaker_config}"
  WatchmakerAdminGroups = "${var.watchmaker_admin_groups}"
  WatchmakerAdminUsers  = "${var.watchmaker_admin_users}"
  WatchmakerOuPath      = "${var.watchmaker_ou_path}"

  DesiredCapacity = "${var.desired_capacity}"
  MinCapacity     = "${var.min_capacity}"
  MaxCapacity     = "${var.max_capacity}"
}
