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
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = var.k8s_master_instance_type
  subnet_id                   = aws_subnet.private[0].id
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  associate_public_ip_address = false # it is in private subnet
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              set -x

              echo "--- STARTING USER_DATA SCRIPT ---"
              date

              echo "--> Running apt-get update"
              apt-get update -y
              if [ $? -ne 0 ]; then echo "APT-GET UPDATE FAILED"; exit 1; fi
              
              echo "--> Running apt-get install curl"
              apt-get install -y curl
              if [ $? -ne 0 ]; then echo "APT-GET INSTALL FAILED"; exit 1; fi

              echo "--> Getting private IP using IMDSv2"
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
              echo "--> Private IP is $PRIVATE_IP"

              echo "--> Running k3s install script"
              curl -sfL https://get.k3s.io | sh -s - server --cluster-init --token ${var.k3s_token} --node-ip $PRIVATE_IP --write-kubeconfig-mode=644
              if [ $? -ne 0 ]; then echo "K3S INSTALL FAILED"; exit 1; fi

              echo "--- FINISHED USER_DATA SCRIPT ---"
              date
              EOF

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_worker" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = var.k8s_worker_instance_type
  subnet_id                   = aws_subnet.private[1].id
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  associate_public_ip_address = false # it is in private subnet
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              set -x

              echo "--- STARTING USER_DATA SCRIPT ---"
              date

              echo "--> Waiting for k8s master to be ready"
              until ping -c1 ${aws_instance.k8s_master.private_ip}; do sleep 10; done

              echo "--> Running apt-get update"
              apt-get update -y
              if [ $? -ne 0 ]; then echo "APT-GET UPDATE FAILED"; exit 1; fi

              echo "--> Running apt-get install curl"
              apt-get install -y curl
              if [ $? -ne 0 ]; then echo "APT-GET INSTALL FAILED"; exit 1; fi

              echo "--> Running k3s worker install script"
              curl -sfL https://get.k3s.io | K3S_URL="https://${aws_instance.k8s_master.private_ip}:6443" K3S_TOKEN="${var.k3s_token}" sh -
              if [ $? -ne 0 ]; then echo "K3S WORKER INSTALL FAILED"; exit 1; fi

              echo "--- FINISHED USER_DATA SCRIPT ---"
              date
              EOF

  tags = {
    Name = "k8s-worker"
  }
}
