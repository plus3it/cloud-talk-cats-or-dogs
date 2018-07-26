# Build outputs
output "build_id" {
  description = "Random ID generated for the build"
  value       = "${random_string.this.id}"
}

output "cats_az" {
  description = "Availability zone displaying cat pictures"
  value       = "${random_shuffle.cats_az.result[0]}"
}

# Load balancer outputs
output "lb_name" {
  description = "Name of the load balancer"
  value       = "${aws_lb.this.name}"
}

output "lb_arn" {
  description = "ARN of the load balancer"
  value       = "${aws_lb.this.arn}"
}

output "lb_arn_suffix" {
  description = "Suffix of the load balancer ARN, for use with CloudWatch Metrics"
  value       = "${aws_lb.this.arn_suffix}"
}

output "lb_dns_name" {
  description = "DNS Name of the load balancer"
  value       = "${aws_lb.this.dns_name}"
}

output "lb_listener_arn" {
  description = "ARN of the load balancer listener"
  value       = "${aws_lb_listener.this.arn}"
}

output "target_group_name" {
  description = "Name of the target group"
  value       = "${aws_lb_target_group.this.name}"
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = "${aws_lb_target_group.this.arn}"
}

output "target_group_arn_suffix" {
  description = "Suffix of the target group ARN, for use with CloudWatch Metrics"
  value       = "${aws_lb_target_group.this.arn_suffix}"
}

# Security group outputs
output "lb_security_group_name" {
  description = "Name of the load balancer security group"
  value       = "${aws_security_group.lb.name}"
}

output "lb_security_group_arn" {
  description = "ARN of the load balancer security group"
  value       = "${aws_security_group.lb.arn}"
}

output "ec2_security_group_name" {
  description = "Name of the ec2 security group"
  value       = "${aws_security_group.ec2.name}"
}

output "ec2_security_group_arn" {
  description = "ARN of the ec2 security group"
  value       = "${aws_security_group.ec2.arn}"
}

# Watchmaker autoscaling module outputs
output "autoscaling_cfn_stack_id" {
  description = "ID of the CloudFormation stack managing the autoscaling group"
  value       = "${module.autoscaling_group.watchmaker-lx-autoscale-stack-id}"
}

output "autoscaling_group_id" {
  description = "ID of the autoscaling group"
  value       = "${module.autoscaling_group.watchmaker-lx-autoscale-autoscaling-group-id}"
}

output "autoscaling_launch_config_id" {
  description = "ID of the autoscaling group"
  value       = "${module.autoscaling_group.watchmaker-lx-autoscale-launch-config-id}"
}
