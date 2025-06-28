variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "A list of availability zones to deploy the subnets in."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "bastion_instance_type" {
  description = "The instance type for the bastion host."
  type        = string
  default     = "t2.micro"
}

variable "bastion_public_key" {
  description = "The public key to use for the bastion host."
  type        = string
}

variable "k8s_public_key" {
  description = "The public key to use for the k8s instances."
  type        = string
}

variable "my_local_ip" {
  description = "Your local IP address to allow access to the k8s cluster."
  type        = string
}

variable "k8s_master_instance_type" {
  description = "The instance type for the k8s master node."
  type        = string
  default     = "t2.micro"
}

variable "k8s_worker_instance_type" {
  description = "The instance type for the k8s worker node."
  type        = string
  default     = "t2.micro"
}

variable "k3s_token" {
  description = "The token for k3s cluster."
  type        = string
  sensitive   = true
}

