variable "project_name" {
  description = "Project name used in resource naming and tags"
  type        = string
  default     = "aws-lz"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "lab_name" {
  description = "Lab identifier"
  type        = string
  default     = "aws-lz-chkp-centralized-inspection"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile name used by the AWS provider"
  type        = string
  default     = ""
}

variable "primary_az" {
  description = "Primary AZ for client VPCs and test instances. Leave empty to auto-select first AZ in region"
  type        = string
  default     = ""
}

variable "inspection_azs" {
  description = "Two AZs used for the Check Point inspection VPC. Leave empty to auto-select first two AZs"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.inspection_azs) == 0 || length(var.inspection_azs) == 2
    error_message = "inspection_azs must contain exactly 2 AZ names, or be empty."
  }
}

variable "inspection_vpc_cidr" {
  description = "CIDR for inspection VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "app1_vpc_cidr" {
  description = "CIDR for App1 VPC (Windows bastion + Linux1)"
  type        = string
  default     = "10.110.0.0/16"
}

variable "app2_vpc_cidr" {
  description = "CIDR for App2 VPC (Linux2)"
  type        = string
  default     = "10.120.0.0/16"
}

variable "bastion_allowed_cidr" {
  description = "Source CIDR allowed to RDP to the Windows bastion"
  type        = string
}

variable "checkpoint_admin_cidr" {
  description = "Source CIDR allowed to access Check Point management UI/SSH"
  type        = string
}

variable "checkpoint_gateways_addresses_cidr" {
  description = "CIDR allowed for Check Point gateways to communicate with management"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_key_path" {
  description = "Path to the SSH public key file used to create EC2 key pair"
  type        = string
  default     = "./keys/lab-key.pub"
}

variable "windows_public_key_path" {
  description = "Optional path to an RSA SSH public key used for the Windows bastion EC2 key pair. If empty, Terraform uses the main key only when it is RSA; otherwise no key pair is attached to Windows."
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name of AWS EC2 key pair"
  type        = string
  default     = "aws-lz-chkp-lab-key"
}

variable "linux_instance_type" {
  description = "Instance type for Linux test instances"
  type        = string
  default     = "t3.small"
}

variable "checkpoint_gateway_instance_type" {
  description = "Instance type for Check Point gateway autoscaling members"
  type        = string
  default     = "c6in.xlarge"
}

variable "checkpoint_management_instance_type" {
  description = "Instance type for Check Point management server"
  type        = string
  default     = "m5.xlarge"
}

variable "checkpoint_gateway_version" {
  description = "Check Point gateway version/license"
  type        = string
  default     = "R82-PAYG-NGTP"
}

variable "checkpoint_management_version" {
  description = "Check Point management version/license"
  type        = string
  default     = "R81.20-PAYG"
}

variable "checkpoint_gateway_sic_key" {
  description = "SIC key for Check Point gateways"
  type        = string
  sensitive   = true
}

variable "checkpoint_gateway_password_hash" {
  description = "Optional admin password hash for Check Point gateways"
  type        = string
  default     = ""
  sensitive   = true
}

variable "checkpoint_gateway_maintenance_mode_password_hash" {
  description = "Optional maintenance mode password hash for Check Point gateways"
  type        = string
  default     = ""
  sensitive   = true
}

variable "checkpoint_management_password_hash" {
  description = "Optional admin password hash for Check Point management"
  type        = string
  default     = ""
  sensitive   = true
}

variable "checkpoint_management_maintenance_mode_password_hash" {
  description = "Optional maintenance mode password hash for Check Point management"
  type        = string
  default     = ""
  sensitive   = true
}
