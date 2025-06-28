output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host."
  value       = aws_instance.bastion.public_ip
}

output "k8s_master_private_ip" {
  description = "Private IP of the k8s master node"
  value       = aws_instance.k8s_master.private_ip
}

output "get_kubeconfig_command" {
  description = "Command to copy the Kubeconfig file from the master to your local machine."
  value       = "scp -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.k8s_master.private_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
}

output "local_kubectl_command" {
  description = "Command to run kubectl locally by tunneling through the bastion."
  value       = "ssh -L 16443:${aws_instance.k8s_master.private_ip}:6443 ubuntu@${aws_instance.bastion.public_ip} -N"
}
