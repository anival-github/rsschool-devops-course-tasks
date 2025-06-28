data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s-key"
  public_key = var.k8s_public_key
}

resource "aws_instance" "k8s_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k8s_master_instance_type
  subnet_id                   = aws_subnet.private[0].id
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  associate_public_ip_address = false # it is in private subnet
  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y curl
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
curl -sfL https://get.k3s.io | sh -s - server --cluster-init --token ${var.k3s_token} --node-ip $PRIVATE_IP --write-kubeconfig-mode=644
EOF

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k8s_worker_instance_type
  subnet_id                   = aws_subnet.private[1].id
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  associate_public_ip_address = false # it is in private subnet
  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y curl
curl -sfL https://get.k3s.io | K3S_URL="https://${aws_instance.k8s_master.private_ip}:6443" K3S_TOKEN="${var.k3s_token}" sh -
EOF

  tags = {
    Name = "k8s-worker"
  }
}
