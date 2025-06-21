variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type = string
  default = "us-east-1
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets."
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for the private subnets."
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "A list of availability zones to deploy the subnets in."
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "bastion_instance_type" {
  description = "The instance type for the bastion host."
  type = string
  default = "t2.micro"
}

variable "bastion_key_name" {
  description = "The name of the key pair to use for the bastion host. Please create this in the AWS console"
  type = string
  default = "bastion-key"
}

