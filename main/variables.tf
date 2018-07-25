### REQUIRED Variables

variable "environment" {
  description = "Type of environment -- must be one of: dev, test, prod"
  type        = "string"
}

variable "ami_owner" {
  description = "Account id/alias of the AMI owner"
  type        = "string"
}

variable "key_pair_name" {
  description = "Keypair to associate to launched instances"
  type        = "string"
}

variable "ec2_extra_security_group_ids" {
  description = "List of additional security groups to add to EC2 instances"
  type        = "list"
}

variable "ec2_subnet_ids" {
  description = "List of subnets where EC2 instances will be launched"
  type        = "list"
}

variable "lb_subnet_ids" {
  description = "List of subnets to associate to the Load Balancer"
  type        = "list"
}

### OPTIONAL Variables

variable "instance_type" {
  default     = "t2.micro"
  description = "Amazon EC2 instance type"
  type        = "string"
}

variable "lb_internal" {
  description = "Boolean indicating whether the load balancer is internal or external"
  type        = "string"
  default     = false
}

variable "min_capacity" {
  type        = "string"
  description = "(Optional) Minimum number of instances in the Autoscaling Group"
  default     = "1"
}

variable "max_capacity" {
  type        = "string"
  description = "(Optional) Maximum number of instances in the Autoscaling Group"
  default     = "2"
}

variable "desired_capacity" {
  type        = "string"
  description = "(Optional) Desired number of instances in the Autoscaling Group"
  default     = "2"
}

variable "pypi_index_url" {
  type        = "string"
  description = "(Optional) URL to the PyPi Index"
  default     = "https://pypi.org/simple"
}

variable "cfn_endpoint_url" {
  type        = "string"
  description = "(Optional) URL to the CloudFormation Endpoint. e.g. https://cloudformation.us-east-1.amazonaws.com"
  default     = "https://cloudformation.us-east-1.amazonaws.com"
}

variable "cfn_get_pip_url" {
  type        = "string"
  description = "(Optional) URL to get-pip.py"
  default     = "https://bootstrap.pypa.io/2.6/get-pip.py"
}

variable "cfn_bootstrap_utils_url" {
  type        = "string"
  description = "(Optional) URL to aws-cfn-bootstrap-latest.tar.gz"
  default     = "https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz"
}

variable "watchmaker_config" {
  type        = "string"
  description = "(Optional) URL to a Watchmaker config file"
  default     = ""
}

variable "watchmaker_ou_path" {
  type        = "string"
  description = "(Optional) DN of the OU to place the instance when joining a domain. If blank and WatchmakerEnvironment enforces a domain join, the instance will be placed in a default container. Leave blank if not joining a domain, or if WatchmakerEnvironment is false"
  default     = ""
}

variable "watchmaker_admin_groups" {
  type        = "string"
  description = "(Optional) Colon-separated list of domain groups that should have admin permissions on the EC2 instance"
  default     = ""
}

variable "watchmaker_admin_users" {
  type        = "string"
  description = "(Optional) Colon-separated list of domain users that should have admin permissions on the EC2 instance"
  default     = ""
}

variable "toggle_update" {
  default     = "A"
  description = "(Optional) Toggle that triggers a stack update by modifying the launch config, resulting in new instances; must be one of: A or B"
  type        = "string"
}
